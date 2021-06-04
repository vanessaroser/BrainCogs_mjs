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
    key.subject_fullname = subjectID;
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
        'x_trajectory',[],'theta_trajectory',[]);
    
    trials(numel(data_files),1) = ...
        struct('left',[],'right',[],'correct',[],'error',[],'omit',[],'forward',[],'exclude',[]);
    
    sessions(numel(data_files),1) = struct(...
        'session_date', [], 'level', [], 'reward_scale', [],...
        'nTrials', [], 'nCompleted', [], 'nForward', [],...
        'pCorrect', [], 'pOmit', [],...
        'mean_velocity', [],...
        'remote_path_behavior_file', []);
    
    %Load each matfile and aggregate into structure
    for j = 1:numel(data_files)
        disp(['Loading ' data_files(j).remote_path_behavior_file '...']);
        [ ~, log ] = loadRemoteVRFile( subjectID, data_files(j).session_date);
        subjects(i).logs(j,:) = log;
        
        %---Trial Data--------------------------------------------------------------------
        
        %Initialize variables aggregated from logs
        start_time = []; duration = []; position = []; velocity = []; 
        theta_trajectory = cell(numel(log.block),1); %Initialize as cell but concatenate as matrix if only one maze
        x_trajectory = cell(numel(log.block),1);
        
        %Anonymous functions for maze dimensions
        ver = @(blockIdx) log.version(min(blockIdx,numel(log.version)));
        maze = @(blockIdx) ver(blockIdx).mazes(log.block(blockIdx).mazeID).variable; %May change based on maze level
        world = @(blockIdx) ver(blockIdx).variables; %Changes with protocol 
        lTrack = @(blockIdx)...
            sum(double(string({maze(blockIdx).lCue, maze(blockIdx).lMemory})));      
        wArm = @(blockIdx)...%Add width of arm minus out-of-range position "border"
            diff(double(string({world(blockIdx).armBorder, world(blockIdx).wArm}))); 
        lMaze = @(blockIdx) lTrack(blockIdx) + wArm(blockIdx);
        
        for k = 1:numel(log.block)
                     
            %Check for glitch (and discuss with Alvaro!) 
            if any(isnan([log.block(k).trial.duration])) %***Do also for empty blocks
                log = trialDataWarning(log, data_files(j).remote_path_behavior_file, k);
            end
            
            start_time = [start_time; [log.block(k).trial.start]'];
            duration = [duration; [log.block(k).trial.duration]'];
            velocity = [velocity; {log.block(k).trial.velocity}'];
            position = [position; {log.block(k).trial.position}'];  
            
            %X-position and view angle as matrices
            ySample = 1:lMaze(k);
            
            x_trajectory{k} = getTrialTrajectories({log.block(k).trial.position}, 'x', ySample);
            theta_trajectory{k} = getTrialTrajectories({log.block(k).trial.position}, 'theta', ySample);
                        
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
        
        %Mean velocity across all iterations in trial (x,y,theta)
        mean_velocity = cell2mat(cellfun(@mean,velocity,'UniformOutput',false));
        
        trialData(j) = struct(...
            'session_date', data_files(j).session_date,...
            'start_time', start_time,...
            'duration', duration,...
            'position', {position},...
            'x_trajectory',x_trajectory,...
            'theta_trajectory',theta_trajectory,...
            'velocity', {velocity},...
            'mean_velocity', mean_velocity);
                        
        %---Trial masks--------------------------------------------------------------------
        
        left = logical([]); right = logical([]); correct = logical([]); omit = logical([]);
        forward = logical([]);
        
        for k = 1:numel(log.block)
            %Choices and outcomes
            left = [left,...
                strcmp({log.block(k).trial.choice},{'L'})];
            right = [right,...
                strcmp({log.block(k).trial.choice},{'R'})];
            correct = [correct,...
                strcmp({log.block(k).trial.choice},{log.block(k).trial.trialType})];
            omit = [omit,...
                strcmp({log.block(k).trial.choice},{Choice.nil})];
               
            %Find trials where mouse turns greater than pi/2 rad L or R in cue or memory segment         
            forward = [forward,...
                getStraightNarrowTrials({log.block(k).trial.position},[0,lTrack(k)])];
        end
        error = ~correct & ~omit;
                
        exclude = omit; %Exclusions as trial mask
        
        trials(j) = struct(...
            'left',left,'right',right,...
            'correct',correct,'error',error,'omit',omit,...
            'forward',forward,'exclude',exclude);  

        
        %---Session data------------------------------------------------------------------
        level = [log.block.mazeID];
        for k = 1:numel(log.block)
            if ~isempty(log.block(k).trial)  %***Fix this to remove these blocks*** 
                reward_scale(k) = [log.block(k).trial(1).rewardScale];
                nTrials(k)  = numel(log.block(k).trial);
            else
                reward_scale(k) = NaN;
                nTrials(k) = 0;
            end
        end
       
        sessions(j) = struct(...
            'session_date', data_files(j).session_date,'level',level,'reward_scale',reward_scale,...
            'nTrials',nTrials,...
            'nCompleted',sum(~exclude),...
            'nForward',sum(forward),...
            'pCorrect',mean(correct(~exclude)),...
            'pOmit',mean(omit),...
            'mean_velocity', mean(mean_velocity(~exclude,2)),... %Mean velocity across all completed trials (x,y,theta)
            'remote_path_behavior_file',data_files(j).remote_path_behavior_file);
    end
    
    %Assign fields to current subject
    subjects(i).trials      = trials;
    subjects(i).trialData   = trialData;
    subjects(i).sessions    = sessions;
    
    clearvars trials trialData sessions;
end

function log = trialDataWarning(log, file_path, block_idx)
[filepath,name,ext] = fileparts(file_path);
warning('\n%s\n%s',...
    ['Problem with ' name ext],...
    ['Missing trial data in block ' num2str(block_idx)],...
    ['Trials have been omitted.']);
badIdx = isnan([log.block(block_idx).trial.duration]);
log.block(block_idx).trial =...
    log.block(block_idx).trial(~badIdx);
