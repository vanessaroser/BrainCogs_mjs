function subjects = getSessionLabels_LMaze( subjects )

%Assign label for session type (Sensory or Alternation)
fields = fieldnames(subjects(1).sessions);
permVect = [1:2,numel(fields)+1,3:numel(fields)];
for i = 1:numel(subjects)
    if isfield(subjects(i).sessions,'sessionType')
        continue
    end  
    sessionLevel = cellfun(@(L) L(end),{subjects(i).sessions.level});
    idx = sessionLevel<7;
    [subjects(i).sessions(idx).sessionType] = deal("Forced");
    idx = ismember(sessionLevel,[7,8]);
    [subjects(i).sessions(idx).sessionType] = deal("Sensory");
    idx = sessionLevel>8;
    [subjects(i).sessions(idx).sessionType] = deal("Alternation");
    
    subjects(i).sessions = orderfields(subjects(i).sessions, permVect); %Place sessionType after 'level'
end

