function [dates, sessionNumbers, sessionsToCrit] = getCriterionSessions(sessions, correctRate)

if numel(correctRate)==1
    correctRate = correctRate.*[1,1,1];
elseif numel(correctRate)<3
    error('Argument 2 must be either a scalar or a 3-element row vector.');
end

%Initialize outputs
[dates, sessionNumbers] = deal(struct("Sensory",[],"Alternation",[])); 

%Filter sessions
sessionType = fieldnames(dates);
% sessions = sessions(ismember(sessions.sessionType, sessionType));

%Find sessions meeting specified performance criteria
session_dates = [sessions.session_date]; 
pCorrect = [sessions.pCorrect];
for i = 1:numel(sessionType)
    %Session date and index
    typeIdx = [sessions.sessionType]==sessionType{i};
    idx = pCorrect > correctRate(i) & typeIdx;
    dates.(sessionType{i}) = session_dates(idx);
    sessionNumbers.(sessionType{i}) = find(idx);
    %Number of sessions needed to reach criterion
    sessionsToCrit.(sessionType{i}) = ...
        find(idx,1,"first") - find(typeIdx,1,"first") + 1; 
end