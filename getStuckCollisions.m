%% getStraightNarrowTrials()
%
% PURPOSE: Generate logical mask indexing trials where mouse maintains
% forward heading throughout specified set of Y-positions (eg, the cue region).
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
Y = pos(:,2); 
theta = pos(:,end);
%Iterations in which y-position & theta were within specified limits
stemIdx = Y >= yLimits(1) & Y < yLimits(2);
thetaIdx = abs(angleMPiPi(theta)) > maxSkidAngle*pi...
    & abs(angleMPiPi(theta)) < pi*(1-maxSkidAngle); 
%Location of collisions, restricted within yLimits and maxSkidAngle
loc = Y(stemIdx & thetaIdx & col);  
% loc = unique(round(loc)); %Round to nearest cm and get unique Y-values
if ~isempty(loc)
    loc = [loc(1); loc(diff([loc(1);loc])>resolution_cm)]; %Get first location and any subsequent locations > specified minimum value from last
end
%Proportion of time spent stuck
pTime = sum(stemIdx & thetaIdx & col) / sum(stemIdx); %Proportion of time spent stuck

%Validation
% dt for each iteration = mean(diff(log.currentTrial.time)) ~10ms
% plot(idx)