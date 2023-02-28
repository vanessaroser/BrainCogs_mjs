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
            trialAvg.(triggers(j)).(trialSpec(k))(cellIdx(1,i):cellIdx(2,i),:) = vertcat(bootStruct(i).bootAvg.(triggers(j)).(trialSpec(k)).cells(:).signal);
        end
    end
    trialAvg.subject(cellIdx(1,i):cellIdx(2,i)) = bootStruct(i).subject;
    trialAvg.expIdx(cellIdx(1,i):cellIdx(2,i)) = i;
    trialAvg.cellID(cellIdx(1,i):cellIdx(2,i)) = bootStruct(i).cellID;
    expID(cellIdx(1,i):cellIdx(2,i)) = string(bootStruct(i).session); 
end

%Take difference over sum for each comparison
selFunc = @(trialAvg1, trialAvg2) (trialAvg2-trialAvg1) ./ (abs(trialAvg2 + trialAvg1)); %abs() to prevent reversal of preference for negative values
for i = 1:numel(params)
    %Domain: time or position
    selectivity.(params(i).comparison).domain = trialAvg.(params(i).trigger).(domain);
    domain = trialAvg.(params(i).trigger).domain;
    wIndex = selectivity.(params(i).comparison).domain > 0; %All values for x>0

    if numel(params(i).trialSpec)==1
        selMat = zscore(trialAvg.(params(i).trigger).(params(i).trialSpec(1)),1,2);
    else
        %Signed Selectivity (preference) as a function of time
        trialType1 = trialAvg.(params(i).trigger).(params(i).trialSpec(1));
        trialType2 = trialAvg.(params(i).trigger).(params(i).trialSpec(2));
        selMat = selFunc(trialType1,trialType2); %Difference over absolute sum
        
        %Preference averaged across x>0 
        winMat = selFunc(mean(trialType1(:,wIndex),2), mean(trialType2(:,wIndex),2)); %Difference over absolute sum
    end
    selectivity.(params(i).comparison).values = selMat;
    
    %Scalar value for entire window following trigger
    selectivity.(params(i).comparison).meanPreference = winMat; %Nprm. difference between grand mean traces
    selectivity.(params(i).comparison).meanSelectivity = abs(winMat); %Norm. absolute difference between grand mean traces 

end
selectivity.subject = trialAvg.subject;
selectivity.session = expID;
selectivity.cellID = trialAvg.cellID;


