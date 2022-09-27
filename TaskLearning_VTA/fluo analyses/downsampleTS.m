%INPUT ARGS
%   cell 'trial_dff': size nCells x 1. Each cell contains either an nTrials x nSamples matrix 
%                       of time series data, or a cell array of size nTrials x 1, containing
%                       dF/F locked to multiple events per trial.
%   
%---------------------------------------------------------------------------------------------------

function [ds_dff, ds_time] = downsampleTS(trial_dff,time,dsFactor)

%Convert trialwise cell arrays to matrices
if iscell(trial_dff{1})
    nEvents = cellfun(@(C) size(C,1), trial_dff{1}); %Number of events per trial
     trial_dff = cellfun(@cell2mat, trial_dff,'UniformOutput',false);
end

%Downsample timeseries by binned averaging
dsIdx = 1:dsFactor:numel(time); %First frame in each bin for averaging
ds_time = time(dsIdx(1:end-1))+ diff(time(dsIdx))/2; %Midpoint between downsampled timepoints
ds_dff = cell(size(trial_dff));
for j = 1:numel(trial_dff)
    for k = 1:numel(ds_time)
        idx = dsIdx(k):dsIdx(k+1)-1;
        ds_dff{j}(:,k) = mean(trial_dff{j}(:,idx),2,"omitnan"); %Assign mean across timepoints
    end
end

%If applicable, convert matrices back to trialwise cell arrays
if exist('nEvents','var')
    ds_dff = cellfun(@(C) mat2cell(C,nEvents), ds_dff,'UniformOutput',false);
end