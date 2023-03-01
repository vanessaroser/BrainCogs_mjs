function [trialAvg, selectivity] = getSummaryTrialAvg( bootStruct, params )

%Determine total number of cells for memory allocation
nCells = arrayfun(@(idx) numel(bootStruct(idx).cellID), 1:numel(bootStruct));
cellIdx = [1, cumsum(nCells(1:end-1))+1; cumsum(nCells)];

for i = 1:numel(bootStruct)
    triggers = [params(:).trigger];
    for j = 1:numel(triggers)
        trialSpec = string(fieldnames(bootStruct(i).bootAvg.(triggers(j))));
        domain = trialSpec(ismember(trialSpec,["t","position"]));
        trialSpec = trialSpec(trialSpec~=domain);
        for k = 1:numel(trialSpec)
            if i==1 %Initialize array using dimensions from first dataset
                trialAvg.(triggers(j)).(domain) = bootStruct(i).bootAvg.(triggers(j)).(domain);
                nBins = numel(trialAvg.(triggers(j)).(domain));
                trialAvg.(triggers(j)).(trialSpec(k)) = NaN(sum(nCells),nBins);
                trialAvg.(triggers(j)).domain = domain;
            end
            trialAvg.(triggers(j)).(trialSpec(k))(cellIdx(1,i):cellIdx(2,i),:) =...
                vertcat(bootStruct(i).bootAvg.(triggers(j)).(trialSpec(k)).cells(:).signal);
        end
    end
    trialAvg.subject(cellIdx(1,i):cellIdx(2,i)) = bootStruct(i).subject;
    trialAvg.expIdx(cellIdx(1,i):cellIdx(2,i)) = i;
    trialAvg.cellID(cellIdx(1,i):cellIdx(2,i)) = bootStruct(i).cellID;
    expID(cellIdx(1,i):cellIdx(2,i)) = string(bootStruct(i).session); 
end

%Take difference over sum for each comparison
Norm = @(trialAvg1, trialAvg2) abs(trialAvg1 + trialAvg2);
Preference = @(trialAvg1, trialAvg2) (trialAvg2-trialAvg1) ./ Norm(trialAvg1,trialAvg2); %abs() to prevent reversal of preference for negative values
Selectivity  = @(trialAvg1, trialAvg2) abs(Preference(trialAvg1, trialAvg2));

for i = 1:numel(params)
    %Domain: time or position
    X = trialAvg.(params(i).trigger).(domain);
    idx = X>=params(i).window(1) & X<=params(i).window(2);
    selectivity.(params(i).comparison).domain = X(idx);
    %Window for within-trial averaging
    wIndex = X>=params(i).avgWindow(1) & X<=params(i).avgWindow(2); %eg, all values for 0<x<(length_of_cue_region)

    if numel(params(i).trialSpec)==1 %eg, for position
        selectivity.(params(i).comparison).zscore = zscore(trialAvg.(params(i).trigger).(params(i).trialSpec(1)),1,2);
    else
        %Selectivity and Preference as a function of time
        trialType1 = trialAvg.(params(i).trigger).(params(i).trialSpec(1));
        trialType2 = trialAvg.(params(i).trigger).(params(i).trialSpec(2));
        
        selectivity.(params(i).comparison).values = Preference(trialType1, trialType2); %Preference over time or space
        selectivity.(params(i).comparison).magnitude = Selectivity(trialType1, trialType2); %Selectivity over time or space
        
        %Scalar Selectivity averaged across window, eg 0--90 cm in cue region 
        selectivity.(params(i).comparison).meanPreference = ...
            Preference(mean(trialType1(:,wIndex),2), mean(trialType2(:,wIndex),2)); %Norm. difference between grand mean traces
        selectivity.(params(i).comparison).meanSelectivity = ...
            Selectivity(mean(trialType1(:,wIndex),2), mean(trialType2(:,wIndex),2)); %Norm. absolute difference between grand mean traces 
    end
end
selectivity.subject = trialAvg.subject;
selectivity.session = expID;
selectivity.cellID = trialAvg.cellID;


