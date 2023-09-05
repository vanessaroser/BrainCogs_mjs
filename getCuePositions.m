%Get Y-positions of sensory cues (towers, puffs) in cm
%   -format is {{leftPositions}{rightPositions}} for each trial 

function [ towerPositions, puffPositions] = getCuePositions(logs, blockIdx)

trials = logs.block(blockIdx).trial;
towerPositions = cell(numel(trials),1);
puffPositions = cell(numel(trials),1);
for i = 1:numel(trials)
    towerPositions{i} = logs.block(blockIdx).trial(i).cuePos;
    if isfield(logs.block(blockIdx).trial(i),'puffPos')
        puffPositions{i} = logs.block(blockIdx).trial(i).puffPos;
    end
end
