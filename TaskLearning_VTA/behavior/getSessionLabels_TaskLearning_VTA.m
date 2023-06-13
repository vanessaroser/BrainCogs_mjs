function subjects = getSessionLabels_TaskLearning_VTA( subjects )

%Assign label for session type (Forced, Visual, or Tactile)
fields = fieldnames(subjects(1).sessions);
permVect = [1:2,numel(fields)+1,3:numel(fields)];
for i = 1:numel(subjects)
    if isfield(subjects(i).sessions,'sessionType')
        continue
    end  
if sum(ismember(fieldnames(subjects(i).logs(end).block(end).trial),["forcedChoice","visualRule","tactileRule"]))==3
    idx = arrayfun(@(ii) subjects(i).logs(ii).block(end).trial(1).forcedChoice, 1:numel(subjects(i).logs));
    for ii = 1:numel(subjects(i).logs)
        a(ii) = subjects(i).logs(ii).block(end).trial(1).forcedChoice
    end
elseif sum(ismember(fieldnames(subjects(i).logs(end).block(end).trial),["forcedChoice","visualRule","tactileRule"]))==3

else
    sessionLevel = cellfun(@(L) L(end),{subjects(i).sessions.level});
    idx = sessionLevel<7;
    [subjects(i).sessions(idx).sessionType] = deal("Forced");
    idx = ismember(sessionLevel, [6,9]);
    [subjects(i).sessions(idx).sessionType] = deal("Sensory");
    idx = ismember(sessionLevel, [7,8]);
    [subjects(i).sessions(idx).sessionType] = deal("Alternation");
end
    
    subjects(i).sessions = orderfields(subjects(i).sessions, permVect); %Place sessionType after 'level'
end

