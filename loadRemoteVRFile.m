function [ path, log ] = loadRemoteVRFile( subjectID, sessionDate)

load_mat = false;
if nargout > 1
    load_mat = true;
end

%Load remote file(s)
key = struct();
key.subject_fullname = char(subjectID); %Must be char, even though annotation says 'string'
key.session_date   = sessionDate;
data_dir = fetch(acquisition.SessionStarted & key, 'new_remote_path_behavior_file');
for i = 1:numel(data_dir)
    path(i) = string(lab.utils.get_path_from_official_dir(data_dir(i).new_remote_path_behavior_file));
end

%Load behavioral file(s)
if load_mat
    for i=1:numel(path)
        try
            data = load(path(i),'log');
            log(i) = data.log;
        catch err
            disp(err)
            disp(['Could not open behavioral file: ', path(i)])
        end
    end
end
