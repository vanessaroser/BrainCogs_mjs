function subjects = getSessionLabels( subjects )

% idx.CNOtests = @(subIdx) ismember([S(subIdx).sessions.session_date],...
%     [S(subIdx).testDates_0mg, S(subIdx).testDates_5mg, S(subIdx).testDates_10mg]);
% idx.sensory = @(subIdx) cellfun(@(Level) all(ismember(Level,4)),{S(subIdx).sessions.level});
% idx.alternation  = @(subIdx) cellfun(@(Level) all(ismember(Level,7)),...
%     {S(subIdx).sessions.level}) & ~idx.CNOtests(subIdx);
% 
% subjects = getCNOTests(subjects, experiment); %Append CNO/DREADD details