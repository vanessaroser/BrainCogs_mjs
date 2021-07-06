%% getStraightNarrowTrials()
%
% PURPOSE: Generate logical mask indexing trials where mouse maintains
% forward heading throughout specified set of Y-positions (eg, the cue region).
%
% MJ Siniscalchi, PNI, 210629
% --------------------------------------------------------------------------------------------------

function [ trial_mask, locations, pCollision ] = getCollisions(position, collision, yLimits)

%Limit focus to within yLimits (eg linear part of maze) 
[locations, pCollision] = cellfun(@(col,pos) filterCollisions(col,pos,yLimits), collision, position, 'UniformOutput', false);
pCollision = cell2mat(pCollision);

%Index trials with sidewall collisions
trial_mask = pCollision > 0; 

function [loc, pCol] = filterCollisions( col, pos, yLimits )
X = pos(:,1); %X-values for position
Y = pos(:,2); %Y-values for position
%Iterations in which y-position was within specified limits
idx = Y >= yLimits(1) & Y < yLimits(2); 
%Location of collisions, restricted within yLimits
loc = [sign(X(col & idx)),Y(col & idx)]; %Simplify X: -1,1 for left,right 
loc = unique(round(loc),'rows'); %Round to nearest cm and get unique X,Y coordinates
%Proportion of maze locations impacted
pCol = size(unique(loc(:,2)),1)/(diff(yLimits)+1); %Use only unique y-values for proportion of maze length in collisions
