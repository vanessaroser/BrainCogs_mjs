function [ds_dff, ds_time] = downsampleTS(trial_dff,time,dsFactor)

dsIdx = 1:dsFactor:numel(time);
ds_time = time(dsIdx(1:end-1))+ diff(time(dsIdx))/2; %Midpoint between downsampled timepoints
ds_dff = cell(size(trial_dff));
for j = 1:numel(trial_dff)
    for k = 1:numel(ds_time)
        idx = dsIdx(k):dsIdx(k+1)-1;
        ds_dff{j}(:,k) = mean(trial_dff{j}(:,idx),2,"omitnan"); %Assign mean across timepoints
    end
end