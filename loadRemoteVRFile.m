function [ path, log ] = loadRemoteVRFile( subjectID, sessionDate, sessionNumber)

load_mat = false;
if nargout > 1
    load_mat = true;
end

%Create key for fetch from DJ
key = struct();
key.subject_fullname = char(subjectID); %Must be char, even though annotation says 'string'
key.session_date   = char(sessionDate);
if nargin > 2
    key.session_number   = sessionNumber;
end

%Load remote file(s)
data_dir = fetch(acquisition.SessionStarted & key, 'new_remote_path_behavior_file');
path = string();
for i = 1:numel(data_dir)
    [~, path(i)] = lab.utils.get_path_from_official_dir(data_dir(i).new_remote_path_behavior_file);
end

%Load behavioral file(s)
if load_mat
    for i = 1:numel(path)
        try
            data = load(path(i),'log');
            log(i) = data.log;
        catch err
            disp(err)
            disp(['Could not open behavioral file: ', path(i)])
        end
    end
end
