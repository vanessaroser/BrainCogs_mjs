for i = 1:numel(subjects)
    idx = find(cellfun(@max,{subjects(i).sessions.level})<7,1,'last');
disp([subjects(i).ID, ' last sensory session: ', datestr(subjects(i).sessions(idx).session_date)]);
end