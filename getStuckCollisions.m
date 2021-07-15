%% getStuckCollisions()
%
% PURPOSE: Get Y-positions where mouse is in contact with side wall and gets caught by friction.
%
% MJ Siniscalchi, PNI, 210629
% --------------------------------------------------------------------------------------------------

function [ stuck_locations, stuck_time ] = getStuckCollisions(position, collision, yLimits, maxSkidAngle, resolution_cm)

%Limit focus to within yLimits (eg linear part of maze) 
[stuck_locations, stuck_time] = cellfun(@(col,pos) filterCollisions(col,pos,yLimits,maxSkidAngle,resolution_cm),...
    collision, position, 'UniformOutput', false);
stuck_time = cell2mat(stuck_time);

function [loc, pTime] = filterCollisions( col, pos, yLimits, maxSkidAngle, resolution_cm)
%Y- and theta-values for each iteration
X = pos(:,1); 
Y = pos(:,2); 
theta = pos(:,end);
%Iterations in which y-position & theta were within specified limits
stemIdx = Y >= yLimits(1) & Y < yLimits(2);
thetaIdx = abs(angleMPiPi(theta)) > maxSkidAngle*pi...
    & abs(angleMPiPi(theta)) < pi*(1-maxSkidAngle); 
%Iterations in which y-position did not change across N iterations
iShift = 10;
stopIdx = circshift(~diff([Y,circshift(Y,iShift)],1,2),-iShift);
%Location of collisions, restricted within yLimits and maxSkidAngle
stuckIdx = stemIdx & thetaIdx & col & stopIdx;
locX = X(stuckIdx)';  %Row vectors for easy concatenation from cell
locY = Y(stuckIdx)';  
loc = [];
if ~isempty(locY)
    idx = [true, diff(locY)>resolution_cm]; %Get first location and any subsequent locations > specified minimum value from last
    loc = [locX(idx); locY(idx)];
end
%Proportion of time spent stuck
pTime = sum(stuckIdx) / sum(stemIdx); %Proportion of time spent stuck
