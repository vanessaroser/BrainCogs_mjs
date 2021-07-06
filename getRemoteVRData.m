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
        struct('left',[],'right',[],'correct',[],'error',[],'omit',[],...
        'forward',[],'stuck',[],'exclude',[]);
    
    sessions(numel(data_files),1) = struct(...
        'session_date', [], 'level', [], 'reward_scale', [],'maxSkidAngle', [],...
        'nTrials', [], 'nCompleted', [], 'nForward', [],...
        'pCorrect', [], 'pOmit', [], 'pStuck', [],...
        'mean_velocity', [], 'mean_pSkid',[],'mean_stuckTime',[],'median_stuckTime',[],...
        'remote_path_behavior_file', []);
    
    %Load each matfile and aggregate into structure
    for j = 1:numel(data_files)
        disp(['Loading ' data_files(j).remote_path_behavior_file '...']);
        [ ~, log ] = loadRemoteVRFile( subjectID, data_files(j).session_date);
        subjects(i).logs(j,:) = log;
        
        %---Trial Data--------------------------------------------------------------------
        
        %Initialize variables aggregated from logs
        [start_time, duration, position, velocity, maxSkidAngle] = deal([]);
        %Initialize as cell
        [theta_trajectory, x_trajectory, collision_locations, stuck_locations, pSkid, stuck_time] =...
            deal(cell(numel(log.block),1));
        
        %Anonymous functions for maze dimensions
        ver = @(blockIdx) log.version(min(blockIdx,numel(log.version)));
        maze = @(blockIdx) ver(blockIdx).mazes(log.block(blockIdx).mazeID).variable; %May change based on maze level
        world = @(blockIdx) ver(blockIdx).variables; %Changes with protocol
        lTrack = @(blockIdx)...
            sum(double(string({maze(blockIdx).lCue, maze(blockIdx).lMemory})));
        wArm = @(blockIdx)...%Add width of arm minus out-of-range position "border"
            diff(double(string({world(blockIdx).armBorder, world(blockIdx).wArm})));
        lMaze = @(blockIdx) lTrack(blockIdx) + wArm(blockIdx);
        
        %Check for empty blocks or trials and remove (discuss with Alvaro!)
        log = removeEmpty(log,data_files(j).remote_path_behavior_file);
        
        for k = 1:numel(log.block)
            Trials = log.block(k).trial;
            start_time = [start_time; [Trials.start]'];
            duration = [duration; [Trials.duration]'];
            velocity = [velocity; {Trials.velocity}'];
            position = [position; {Trials.position}'];
            
            %X-position and view angle as matrices
            ySample = 1:lMaze(k);
            x_trajectory{k} = getTrialTrajectories({Trials.position}, 'x', ySample);
            theta_trajectory{k} = getTrialTrajectories({Trials.position}, 'theta', ySample);
            
            %Collision locations along main stem
            lSlide = str2double(world(k).wTrack)/2; %Set as default in stickyWalls.m
            yLimits = [0, str2double(maze(k).lCue) - lSlide];
            [ ~, collision_locations{k}, pSkid{k} ] =...
                getCollisions({Trials.position}, {Trials.collision}, yLimits);
            
            %Collisions with engagement of "sticky walls"
            if isfield(maze(k),'maxSkidAngle') && isfinite(str2double(maze(k).maxSkidAngle)) %Threshold skid angle eliciting friction
                maxSkidAngle(k) = str2double(maze(k).maxSkidAngle);
                resolution = 10;
                [stuck_locations{k}, stuck_time{k}] = ...
                    getStuckCollisions({Trials.position}, {Trials.collision}, yLimits, maxSkidAngle(k),resolution);
            else
                maxSkidAngle(k) = Inf; %Default value
                stuck_locations{k} = cell(numel(Trials),1); %Locations where sticky-wall behavior occured, rounded in cm
                stuck_time{k} = nan(1,numel(Trials)); %Proportion of iterations spent stuck to wall
            end
            
        end
        
        %Concatenate as matrix if only one maze
        if numel([log.block.mazeID])==1 || isequal(log.block.mazeID)
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
            'stuck_time', [stuck_time{:}]',... %Proportion of time stuck to sidewalls when "stickywalls" enforced
            'pSkid', [pSkid{:}]',... %Proportion of maze in collision with sidewalls
            'mean_velocity', cell2mat(cellfun(@mean,velocity,'UniformOutput',false))); %Mean velocity across all iterations in trial (x,y,theta)
        
        %---Trial masks--------------------------------------------------------------------
        
        %Initialize
        empty = cell(6,1);
        empty(1:numel(empty)) = {logical([])};
        [left, right, correct, omit, forward, stuck] = deal(empty{:});
        
        for k = 1:numel(log.block)
            %Choices and outcomes
            Trials = log.block(k).trial;
            left = [left, strcmp({Trials.choice},{'L'})];
            right = [right, strcmp({Trials.choice},{'R'})];
            correct = [correct, strcmp({Trials.choice},{Trials.trialType})];
            omit = [omit, strcmp({Trials.choice},{Choice.nil})];
            
            %Find trials where mouse turns greater than pi/2 rad L or R in cue or memory segment
            forward = [forward, getStraightNarrowTrials({Trials.position},[0,lTrack(k)])];
            %Find trials where mouse gets stuck after collision along cue segment
            stuck = [stuck, stuck_time{k}>0];
        end
        
        error = ~correct & ~omit;
        exclude = omit; %Exclusions as trial mask
        
        trials(j) = struct(...
            'left',left,'right',right,...
            'correct',correct,'error',error,'omit',omit,...
            'forward',forward,'stuck',stuck,'exclude',exclude);
        
        %---Session data------------------------------------------------------------------
        
        %Block data
        [reward_scale, nTrials] = deal([]); %Initialize
        level = [log.block.mazeID];
        for k = 1:numel(log.block)
            reward_scale(k) = [log.block(k).trial(1).rewardScale];
            nTrials(k)  = numel(log.block(k).trial);
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
