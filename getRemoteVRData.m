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
    trials(numel(data_files),1) = struct('correct',[],'error',[],'omit',[],'exclude',[]);
    
    trialData(numel(data_files),1) = struct('session_date', [],'start_time',[],...
        'duration',[],'position',[],'velocity',[],'mean_velocity',[]);
    
    sessions(numel(data_files),1) = struct(...
        'session_date', [], 'level', [], 'reward_scale', [],...
        'nTrials', [], 'nCompleted', [], 'pCorrect', [], 'pOmit', [],...
        'mean_velocity', [],...
        'remote_path_behavior_file', []);
    
    %Load each matfile and aggregate into structure
    for j = 1:numel(data_files)
        disp(['Loading ' data_files(j).remote_path_behavior_file '...']);
        [ ~, log ] = loadRemoteVRFile( subjectID, data_files(j).session_date);
        subjects(i).logs(j,:) = log;
        
        %---Trial Data--------------------------------------------------------------------
        
        %Trial masks
        correct = []; omit = [];
        for k = 1:numel(log.block)
            correct = [correct,...
                strcmp({log.block(k).trial.choice},{log.block(k).trial.trialType})];
            omit = [omit,...
                strcmp({log.block(k).trial.choice},Choice.nil)];
        end
        error = ~correct & ~omit;
        
        exclude = omit; %Exclusions as trial mask
        
        trials(j) = struct('correct',correct,'error',error,'omit',omit,'exclude',exclude);
        
        %---Trial data--------------------------------------------------------------------
        
        start_time = []; duration = []; position = []; velocity = []; 
        for k = 1:numel(log.block)
            start_time = [start_time; [log.block(k).trial.start]'];
            duration = [duration; [log.block(k).trial.duration]'];
            velocity = [velocity; {log.block(k).trial.velocity}'];
            position = [position; {log.block(k).trial.position}'];            
        end
        start_time = start_time-start_time(1); %Align to first trial
        
        %Mean velocity across all iterations in trial (x,y,theta)
        mean_velocity = cell2mat(cellfun(@mean,velocity,'UniformOutput',false));
        
        trialData(j) = struct(...
            'session_date', data_files(j).session_date,...
            'start_time', start_time,...
            'duration', duration,...
            'position', {position},...
            'velocity', {velocity},...
            'mean_velocity', mean_velocity);
        
        %---Session data------------------------------------------------------------------
        level = [log.block.mazeID];
        for k = 1:numel(log.block)
            if ~isempty(log.block(k).trial)
                reward_scale(k) = [log.block(k).trial(1).rewardScale];
                nTrials(k)  = numel(log.block(k).trial);
            else
                reward_scale(k) = NaN;
                nTrials(k) = 0;
            end
        end
        nCompleted = sum(~exclude);
        pCorrect = mean(correct(~exclude)); % all(exclude(trialIdx)==[trials(i).omit]) for now...
        pOmit = mean(omit);
        
        %Mean velocity across all completed trials (x,y,theta)
        mean_velocity = mean(mean_velocity(~exclude,2));
        
        sessions(j) = struct(...
            'session_date', data_files(j).session_date,'level',level,'reward_scale',reward_scale,...
            'nTrials',nTrials,'nCompleted',nCompleted,'pCorrect',pCorrect,'pOmit',pOmit,...
            'mean_velocity', mean_velocity,...
            'remote_path_behavior_file',data_files(j).remote_path_behavior_file);
    end
    
    %Assign fields to current subject
    subjects(i).trials      = trials;
    subjects(i).trialData   = trialData;
    subjects(i).sessions    = sessions;
    
    clearvars trials trialData sessions;
end