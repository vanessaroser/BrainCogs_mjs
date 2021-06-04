%%% getTrialTrajectories()
% Find the trajectory in x or theta as a function of y-position in maze.
% Modified from original sampleViewAngleVsY.m (au:Sue Ann Koay) to handle x-position or view angle
% Michael Siniscalchi, PNI, 210604

function [position_mat, yPos, yIndex] = getTrialTrajectories(position, dimString, ySample)
%Select axes index based on input string
idx = {["x","y","theta"],[1,2,3]};
idx = idx{2}(idx{1}==dimString); %Index into position{i}(:,idx)

%Get positions corresponding to input sample y-positions
yPos            = cellfun(@(x) cummax(x(:,2)), position, 'UniformOutput', false);
yIndex          = accumfun(2, @(x) binarySearch(x, ySample, 1, 1)', yPos);
position_mat    = accumfun(2, @(x) position{x}(yIndex(:,x), idx), 1:numel(position));

%This code taken from sampleViewAngleVsY(), written by Sue Ann Koay
%   A couple issues with cummax(y) strategy for dealing with
%   trials where the mouse turns back:
%   (1) disjointed trajectories, and
%   (2) x-position output for arms of the maze is a little weird.