function [ R, changePt ] = getRotationsPerRev( logs )

for sessionIdx = 1:numel(logs)
    R(sessionIdx) = logs(sessionIdx).animal.virmenRotationsPerRev;
    changePt = find(isnan(R),1,'last')+1;
end


