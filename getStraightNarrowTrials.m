function trialMask = getStraightNarrowTrials(position, yLimits)

%Limit focus to within yLimits (eg linear part of maze) 
pos_track = cellfun(@(pos) limitRange(pos, yLimits), position, 'UniformOutput', false);

%Index trials where >pi/2 turn is made
trialMask = cellfun(@(P) ~any(abs(P(:,3)) > pi/2), pos_track); 

function pos = limitRange( pos, yLimits )
Y = pos(:,2); %Y-values for position
pos_idx = Y >= yLimits(1) & Y < yLimits(2);
pos = pos(pos_idx,:);



%--- Notes ---------------------------------------------------

% Interesting... arrayfun() is slightly faster than the loop.
% %Grab position matrices from all trials in each block
% tic
% for i = 1:numel(log.block)
%     pos{i} = {log.block(i).trial.position};
% end
% pos = [pos{:}]; %Concatenate
% toc

