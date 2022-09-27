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
    trialAvg.expID(cellIdx(1,i):cellIdx(2,i)) = i;
    trialAvg.cellID(cellIdx(1,i):cellIdx(2,i)) = bootStruct(i).cellID;
end

%Take difference over sum for each comparison
for i = 1:numel(params)
    trigger = params(i).trigger;

    if numel(params(i).trialSpec)==1
        selMat = zscore(trialAvg.(params(i).trigger).(params(i).trialSpec(1)),1,2);
        %         selectivity.(params(i).comparison) = trialAvg.(params(i).trigger).(params(i).trialSpec(1));
    else
        trialType1 = trialAvg.(params(i).trigger).(params(i).trialSpec(1));
        trialType2 = trialAvg.(params(i).trigger).(params(i).trialSpec(2));
        %     selectivity.(params(i).comparison) = ...
        %         (trialType2-trialType1)./(trialType2+trialType1);
        selMat = (trialType2-trialType1) ./ (abs(trialType2)+abs(trialType1)); %Difference over absolute sum
    end
    selectivity.(params(i).comparison).values = selMat;
    
    %Append Domain: time or position
    domain = trialAvg.(params(i).trigger).domain;
    selectivity.(params(i).comparison).domain = trialAvg.(params(i).trigger).(domain);
end


