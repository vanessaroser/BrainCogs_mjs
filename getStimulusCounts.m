%%% getStimulusCounts()
%
% Purpose: to count the number of visual (towers) and tactile(air-puffs)
% presented in each trial.
%
% eg eventTimes = subjects(2).trialData(end).eventTimes;
%
%--------------------------------------------------------------------------------------------------- 

function count = getStimulusCounts(eventTimes)

for i=1:numel(eventTimes)
    count.towers(i) = sum(~isnan(eventTimes(i).towers.all));
    count.puffs(i) = sum(~isnan(eventTimes(i).puffs.all));
end