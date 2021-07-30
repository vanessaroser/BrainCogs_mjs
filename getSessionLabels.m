function subjects = getSessionLabels( subjects )

%Assign label for session type (Sensory or Alternation)
fields = fieldnames(subjects(1).sessions);
permVect = [1:2,numel(fields)+1,3:numel(fields)];
for i = 1:numel(subjects)
    if isfield(subjects(i).sessions,'sessionType')
        continue
    end    
    idx = cellfun(@max,{subjects(i).sessions.level})<7;
    [subjects(i).sessions(idx).sessionType] = deal("Sensory");
    [subjects(i).sessions(~idx).sessionType] = deal("Alternation");
    subjects(i).sessions = orderfields(subjects(i).sessions, permVect); %Place sessionType after 'level'
end

