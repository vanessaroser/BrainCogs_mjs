function bootAvg = calc_trialAvgFluo( trial_dFF, trials, params, bootAvg )

% Unpack variables from structures
trialSpec = params.trialSpec;
trigger = params.trigger;
subtractBaseline = params.subtractBaseline;
time = trial_dFF.t;
position = trial_dFF.position;
trial_dff = trial_dFF.(params.trigger); %Fix cue,turn,arm entry event code...

%Check for spatial-position or time series analyses
if trigger ~= "cueRegion"
    
    %Convert trialwise cell arrays to matrices, if applicable
    if iscell(trial_dff{1})
        nEvents = cellfun(@(C) size(C,1), trial_dff{1}); %Number of events per trial
        trial_dff = cellfun(@cell2mat, trial_dff,'UniformOutput',false);
    end

    % Downsample by time if specified
    if params.dsFactor > 1
        [trial_dff, time] = downsampleTS(trial_dff,time,params.dsFactor);
    end

    % Truncate dFF and time vector if specified
    wIndex = time >= params.timeWindow(1) & time <= params.timeWindow(2);
    time = time(wIndex);
    trial_dff = cellfun(@(DFF) DFF(:,wIndex), trial_dff,'UniformOutput',false);
    bootAvg.t = time;

    %If applicable, convert matrices back to trialwise cell arrays
    if exist('nEvents','var')
        trial_dff = cellfun(@(C) mat2cell(C,nEvents), trial_dff,'UniformOutput',false);
    end

else %Separate analysis for dF/F binned by spatial position
    % Truncate dFF and position vector if specified
    wIndex = position >= params.positionWindow(1) & position <= params.positionWindow(2);
    bootAvg.position = position(wIndex); %For spatial position series
end

% Calculate event-averaged dF/F
for i = 1:numel(trial_dff)
    disp(['Calculating trial-averaged dF/F for cell ' num2str(i) '/' num2str(numel(trial_dff))]);  
    for k = 1:numel(trialSpec)
        if numel(trialSpec{k})>1
            subset_label = join(trialSpec{k},'_');
        else
            subset_label = trialSpec{k};
        end
        disp(subset_label);
        trialMask = getMask(trials,trialSpec{k}); %Logical mask for specified combination of trials
        dff = trial_dff{i}(trialMask, wIndex); %Get dFF in specified window for subset of trials specified by trialMask
        
        %Convert trialwise cell arrays to matrices
        if iscell(dff)
            dff = cell2mat(dff);
        end

        %Subtract baseline, if specified
        if isfield(params,'subtractBaseline') && params.subtractBaseline
            if isfield(bootAvg,'t')
                baseline = mean(dff(:,bootAvg.t<=0),2,"omitnan"); %Baseline = mean of windowed timepoints prior to event
            else
                baseline = mean(dff(:,bootAvg.position<=0),2,"omitnan");
            end
            dff = dff - baseline;
        end
        
        dff = dff(~isnan(sum(dff,2)),:); %Exclude traces that include NaNs
        bootAvg.(subset_label).cells(i) = getTrialBoot(dff,subset_label,params);
    end   
end
