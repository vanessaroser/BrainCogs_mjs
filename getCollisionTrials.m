%% getStraightNarrowTrials()
%
% PURPOSE: Generate logical mask indexing trials where mouse maintains
% forward heading throughout specified set of Y-positions (eg, the cue region).
%
% MJ Siniscalchi, PNI, 210629
% --------------------------------------------------------------------------------------------------

function [ trialMask, locations ] = getCollisionTrials(position, yLimits)

%Limit focus to within yLimits (eg linear part of maze) 
collisions = cellfun(@(pos) limitRange(pos, yLimits), position, 'UniformOutput', false);

%Index trials with reversed heading within cue region
trialMask = cellfun(@(theta) ~any(abs(angleMPiPi(theta)) > pi/2), theta_track); 

function theta_track = limitRange( pos, yLimits )
Y = pos(:,2); %Y-values for position
pos_idx = Y >= yLimits(1) & Y < yLimits(2);
theta_track = pos(pos_idx,end); %View angle is position(:,end)



%--- Notes ---------------------------------------------------

%Code used to include these lines; removed and replaced with use of angleMPiPi()
%
% %Subtract complete turns prior to cue region entry
% theta_track = cellfun(@recenterTheta, theta_track, 'UniformOutput', false);

% function theta = recenterTheta(theta)
% if ~isempty(theta)
%     nTurns = floor(abs(theta(1))/(2*pi)) * sign(theta(1)); %Number and direction of complete turns at cue region entry
%     theta = theta - nTurns*2*pi; %Subtract turns from start region
% end
