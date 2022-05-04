function bootAvg = calc_trialAvgFluo( trial_dFF, trials, params )

% Unpack variables from structures
trialSpec = params.trialSpec;
trigger = params.trigger;
time = trial_dFF.t;
trial_dff = trial_dFF.(params.trigger);

%Check for spatial-position or time series analyses
if trigger ~= "cueRegion" 
    % Downsample by time if specified
    if params.dsFactor > 1
        [trial_dff, time] = downsampleTS(trial_dff,time,params.dsFactor);
    end

    % Truncate dFF and time vector if specified
    idx = time >= params.window(1) & time <= params.window(2);
    time = time(idx);
    trial_dff = cellfun(@(DFF) DFF(:,idx), trial_dff,'UniformOutput',false);
    bootAvg.t = time;
else
    bootAvg.position = trial_dFF.position; %For spatial position series
end

% Calculate trial-averaged dF/F
for i = 1:numel(trial_dff)
    disp(['Calculating trial-averaged dF/F for cell ' num2str(i) '/' num2str(numel(trial_dff))]);  
    for k = 1:numel(trialSpec)
        if numel(trialSpec{k})>1
            subset_label = join(trialSpec{k},'_');
        else
            subset_label = trialSpec{k};
        end
        trialMask = getMask(trials,trialSpec{k}); %Logical mask for specified combination of trials
        dff = trial_dff{i}(trialMask,:); %Get subset of trials specified by trialMask
        dff = dff(~isnan(sum(dff,2)),:);
        bootAvg.(subset_label).cells(i) = getTrialBoot(dff,subset_label,params);
    end   
end
