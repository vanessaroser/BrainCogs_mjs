function [ path, log ] = loadRemoteVRFile( subjectID, sessionDate)

load_mat = false;
if nargout > 1
    load_mat = true;
end

%Load remote file (from Alvaro Luna)
key = struct();
key.subject_fullname = char(subjectID); %Must be char, even though annotation says 'string'
key.session_date   = sessionDate;
data_dir = fetch(acquisition.SessionStarted & key, 'remote_path_behavior_file');
[~, path] = lab.utils.get_path_from_official_dir(data_dir.remote_path_behavior_file);

%Load behavioral file
if load_mat
    try
        data = load(path,'log');
        log = data.log;
    catch err
        disp(err)
        disp(['Could not open behavioral file: ', path])
    end
end
