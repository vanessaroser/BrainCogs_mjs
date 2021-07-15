function subjects = getRemoteVRData( experiment, subjects )

if isempty(experiment)
    experiment = '';
end

%Aggregate log data into single struct by subject
%#ok<*AGROW>
for i = 1:numel(subjects)
    
    %Subject ID, ie DB key 'subject_fullname'
    subjectID = subjects(i).ID;
    
    %Get bucket paths
    key.subject_fullname = char(subjectID); %Must be char, even though annotation says 'string'
    data_files = fetch(acquisition.SessionStarted & key, 'remote_path_behavior_file');
    session_file = cell(numel(data_files),1);
    include = false(numel(data_files),1);
    for j = 1:numel(data_files)
        [~, session_file{j}] = lab.utils.get_path_from_official_dir(data_files(j).remote_path_behavior_file);
        include(j) = isfile(session_file{j});
    end
    
    %Filter by experiment
    include(~contains(session_file,experiment)) = false; %Exclude filenames that do not contain 'experiment'
    data_files = data_files(include);
    
    %Initialize output structures
    trialData(numel(data_files),1) = struct('session_date', [],'start_time',[],...
        'duration',[],'position',[],'velocity',[],'mean_velocity',[],...
        'x_trajectory',[],'theta_trajectory',[],...
        'collision_locations',[],'pSkid',[],'stuck_locations',[],'stuck_time',[]);
    
    trials(numel(data_files),1) = ...
        struct('left',[],'right',[],'leftCue',[],'rightCue',[],...
        'correct',[],'error',[],'omit',[],...
        'forward',[],'stuck',[],'conflict',[],'exclude',[],...
        'blockIdx',[]);
    
    sessions(numel(data_files),1) = struct(...
        'session_date', [], 'level', [], 'reward_scale', [],'maxSkidAngle', [],...
        'nTrials', [], 'nCompleted', [], 'nForward', [],...
        'pCorrect', [], 'pOmit', [], 'pStuck', [],...
        'mean_velocity', [], 'mean_pSkid',[],'mean_stuckTime',[],'median_stuckTime',[],...
        'remote_path_behavior_file', []);
    
    %Load each matfile and aggregate into structure
    for j = 1:numel(data_files)
        disp(['Loading ' data_files(j).remote_path_behavior_file '...']);
        [ ~, logs ] = loadRemoteVRFile( subjectID, data_files(j).session_date);
        subjects(i).logs(j,:) = logs;
        
        %---Trial Data--------------------------------------------------------------------
                     
        %Anonymous functions for maze dimensions
        ver = @(blockIdx) logs.version(min(blockIdx,numel(logs.version)));
        maze = @(blockIdx) ver(blockIdx).mazes(logs.block(blockIdx).mazeID).variable; %May change based on maze level
        world = @(blockIdx) ver(blockIdx).variables; %Changes with protocol
        lTrack = @(blockIdx)...
            sum(double(string({maze(blockIdx).lCue, maze(blockIdx).lMemory})));
        wArm = @(blockIdx)...%Add width of arm minus out-of-range position "border"
            diff(double(string({world(blockIdx).armBorder, world(blockIdx).wArm})));
        lMaze = @(blockIdx) lTrack(blockIdx) + wArm(blockIdx);
        
        %Check for empty blocks or trials and remove (discuss with Alvaro!)
        logs = removeEmpty(logs,data_files(j).remote_path_behavior_file);
        
        %Initialize trial variables aggregated from logs
        blockIdx = nan(1,numel([logs.block.trial]));
        [start_time, duration, pSkid, stuck_time] = deal(nan(numel(blockIdx),1));
        [position, velocity, collision_locations, stuck_locations] = deal(cell(numel(blockIdx),1));
        %Initialize as one cell per block
        [theta_trajectory, x_trajectory] = deal(cell(numel(logs.block),1)); %Matrices: nLocation x nTrial
        
        %Get maximum skid angle before engagement of friction
        maxSkidAngle = inf(1,numel(logs.block));
        if isfield(maze(1),'maxSkidAngle') 
            maxSkidAngle = arrayfun(@(blockIdx) str2double(maze(blockIdx).maxSkidAngle), 1:numel(logs.block)); 
        end

        firstTrial = 1; %log.block(k).firstTrial cannot be used: empty trials were removed with removeEmpty()
        for k = 1:numel(logs.block)
            
            %Index for trials in current block
            Trials = logs.block(k).trial;
            lastTrial = firstTrial + numel(Trials) - 1;
            blockIdx(firstTrial:lastTrial) = k;
            
            start_time(blockIdx==k) = [Trials.start];
            duration(blockIdx==k)  = [Trials.duration];
            velocity(blockIdx==k)  = cellfun(@double,{Trials.velocity},'UniformOutput',false);
            position(blockIdx==k)  = cellfun(@double,{Trials.position},'UniformOutput',false);
            
            %X-position and view angle as matrices
            ySample = 1:lMaze(k);
            x_trajectory{k} = getTrialTrajectories({Trials.position}, 'x', ySample);
            theta_trajectory{k} = getTrialTrajectories({Trials.position}, 'theta', ySample);
            
            %Collision locations along main stem
            yLimits = [0, str2double(maze(k).lCue)];
            [ ~, collision_locations(blockIdx==k), pSkid(blockIdx==k) ] =...
                getCollisions({Trials.position}, {Trials.collision}, yLimits);
          
            %Collisions with engagement of "sticky walls"
            resolution = 5;
%             if isfield(Trials,'frictionEngagedVec') && 
%                 stuck_locations(blockIdx==k) = cellfun(@(pos,fric) unique(pos(fric,1:2),'rows'),...
%                     {Trials.position},{Trials.frictionEngagedVec},'UniformOutput',false);
            if isfinite(maxSkidAngle(k))
                [stuck_locations(blockIdx==k), stuck_time(blockIdx==k)] = ...
                    getStuckCollisions({Trials.position}, {Trials.collision}, yLimits, maxSkidAngle(k),resolution);
            end
            
            %Increment trial Idx
            firstTrial = lastTrial+1;
        end
        
        %Concatenate as matrix if only one maze
        if numel([logs.block.mazeID])==1 || isequal(logs.block.mazeID)
            x_trajectory = [x_trajectory{:}];
            theta_trajectory = [theta_trajectory{:}];
        else
            x_trajectory = {x_trajectory};
            theta_trajectory = {theta_trajectory};
        end
        
        start_time = start_time-start_time(1); %Align to first trial
        
        trialData(j) = struct(...
            'session_date', datetime(data_files(j).session_date),...
            'start_time', start_time,...
            'duration', duration,...
            'position', {position},...
            'x_trajectory',x_trajectory,...
            'theta_trajectory',theta_trajectory,...
            'velocity', {velocity},...
            'collision_locations', {collision_locations},... %Unique X,Y locations of collisions at cm resolution (X simplified to -1,1 for L/R walls)
            'stuck_locations', {stuck_locations},...
            'stuck_time', stuck_time,... %Proportion of time stuck to sidewalls when "stickywalls" enforced
            'pSkid', pSkid,... %Proportion of maze in collision with sidewalls
            'mean_velocity', cell2mat(cellfun(@mean,velocity,'UniformOutput',false))); %Mean velocity across all iterations in trial (x,y,theta)
        
        %---Trial masks--------------------------------------------------------------------
        
        %Initialize
        [left, right, leftCue, rightCue,...
            correct, omit, conflict, forward, stuck] = deal(false(1,numel(blockIdx)));
        
        for k = 1:numel(logs.block)
            %Cues, choices, and outcomes
            Trials = logs.block(k).trial;
            leftCue(blockIdx==k) = cellfun(@(C) sum(C(1,:))>sum(C(2,:)),{Trials.cueCombo});
            rightCue(blockIdx==k) = cellfun(@(C) sum(C(1,:))<sum(C(2,:)),{Trials.cueCombo});
            left(blockIdx==k) = [Trials.choice]==Choice.L;
            right(blockIdx==k) = [Trials.choice]==Choice.R;
            correct(blockIdx==k) = [Trials.choice]==[Trials.trialType];
            omit(blockIdx==k) = [Trials.choice]==Choice.nil;
            
            %Trials where sensory and alternation rules conflict
            conflict(blockIdx==k) = int8([Trials.trialType]) ~= int8(rightCue(blockIdx==k))+1; %R,L choice enumeration = 1,2           
            %Trials where mouse turns greater than pi/2 rad L or R in cue or memory segment
            forward(blockIdx==k) = getStraightNarrowTrials({Trials.position},[0,lTrack(k)]);
            %Trials where mouse gets stuck after collision along cue segment
            stuck(blockIdx==k) = stuck_time(blockIdx==k)>0;
        end
        
        error = ~correct & ~omit;
        exclude = omit; %Exclusions as trial mask

        
        trials(j) = struct(...
            'left',left,'right',right,'leftCue',leftCue,'rightCue',rightCue,...
            'correct',correct,'error',error,'omit',omit,...
            'forward',forward,'stuck',stuck,...
            'exclude',exclude,'conflict',conflict,...
            'blockIdx',blockIdx);
        
        %---Session data------------------------------------------------------------------
        
        %Block data
        [reward_scale, nTrials] = deal([]); %Initialize
        level = [logs.block.mazeID];
        for k = 1:numel(logs.block)
            reward_scale(k) = [logs.block(k).trial(1).rewardScale];
            nTrials(k)  = numel(logs.block(k).trial);
        end
        
        sessions(j) = struct(...
            'session_date', datetime(data_files(j).session_date),...
            'level', level,...
            'reward_scale', reward_scale,...
            'maxSkidAngle', maxSkidAngle,...
            'nTrials', nTrials,...
            'nCompleted', sum(~omit),...
            'nForward', sum(forward),...
            'pCorrect', mean(correct(~omit)),...
            'pOmit', mean(omit),...
            'pStuck', mean(stuck(~omit)),...
            'mean_velocity', mean(trialData(j).mean_velocity(forward & ~omit,2)),... %Mean velocity across all completed trials (x,y,theta)
            'mean_pSkid', mean(trialData(j).pSkid(forward & ~omit)),... %Mean proportion of maze where mouse skidded along walls
            'mean_stuckTime', mean(trialData(j).stuck_time,'omitnan'),...
            'median_stuckTime', median(trialData(j).stuck_time,'omitnan'),...
            'remote_path_behavior_file',data_files(j).remote_path_behavior_file);
    end
    
    %Assign fields to current subject
    subjects(i).trials      = trials;
    subjects(i).trialData   = trialData;
    subjects(i).sessions    = sessions;
    
    clearvars trials trialData sessions;
end


function log = removeEmpty(log, file_path)

[~, name, ext] = fileparts(file_path);
for i = 1:numel(log.block)
    if any(isnan([log.block(i).trial.duration]))
        warning('\n%s',...
            ['Problem with ' name ext],...
            ['Missing trial data in block ' num2str(i)],...
            ['Trials have been omitted.']);
        badTrials = isnan([log.block(i).trial.duration]);
        log.block(i).trial =...
            log.block(i).trial(~badTrials);
    end
end

badBlocks = cellfun(@isempty,{log.block.trial});
if any(badBlocks)
    warning('\n%s',...
        ['Problem with ' name ext]);
    for i = find(badBlocks)
        warning('\n%s',...
            ['Block ' num2str(i),' is empty.'],...
            ['Block has been omitted.']);
    end
    log.block = log.block(~badBlocks);
end
