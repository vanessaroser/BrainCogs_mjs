function idx = getExcessTravelTrials( position, yLimits )

%Include only the main stem of maze
pos_track = cellfun(@(pos) limitRange(pos, yLimits), position, 'UniformOutput', false);

%Euclidean distance
distance = @(x,y) sqrt(x.^2 + y.^2);
idx = cellfun(@(pos)...
    sum(distance(diff(pos(:,1)),diff(pos(:,2)))) > 1.1*diff(yLimits),... cumulative distance
    pos_track);

%Only distance in Y-position
% idx = cellfun(@(pos)...
%     sum(abs(diff(pos(:,2)))) > 1.1*diff(yLimits),... cumulative distance
%     pos_track);

function pos = limitRange( pos, yLimits )
Y = pos(:,2); %Y-values for position
pos_idx = Y >= yLimits(1) & Y < yLimits(2);
pos = pos(pos_idx,:);