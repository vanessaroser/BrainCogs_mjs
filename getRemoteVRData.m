function data = getRemoteVRData( experiment, subjects )

if isempty(experiment)
    experiment = '';
end

%Aggregate log data into single struct by subject
for i=1:numel(subjects)

    %Subject ID, ie DB key 'subject_fullname'
    subjectID = subjects(i).ID;
    
    %Get bucket paths
    key.subject_fullname = subjectID;
    data_dir = fetch(acquisition.SessionStarted & key, 'remote_path_behavior_file');
    session_file = cell(numel(data_dir),1);
    include = false(numel(data_dir),1);
    for j=1:numel(data_dir)
        [~, session_file{j}] = lab.utils.get_path_from_official_dir(data_dir(j).remote_path_behavior_file);
        include(j) = isfile(session_file{j});
    end
    
    %Filter by experiment
    include(~contains(session_file,experiment)) = false; %Exclude filenames that do not contain 'experiment'
    data_dir = data_dir(include);
    
    %Load each matfile and aggregate into structure
    for j = 1:numel(data_dir)      
        disp(['Loading ' session_file{j} '...']);
            [ ~, log ] = loadRemoteVRFile( subjectID, data_dir(j).session_date);
            data.(subjectID).logs(j,:) = log;
    end
end