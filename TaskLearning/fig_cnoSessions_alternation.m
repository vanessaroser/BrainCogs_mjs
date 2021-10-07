function figs = fig_cnoSessions_alternation( subjects, var, nPreTestSessions )

setup_figprops('placeholder'); %Customize for performance plots

%Plotting params
lineWidth = 2;
shadeOffset = 0.5;

%Colors
cbrew = brewColorSwatches();
colors = struct('pCorrect', cbrew.blue, 'pOmit', cbrew.orange, 'mean_velocity',...
    cbrew.green, 'nCompleted', cbrew.black);

%Prefix for save
prefix = ['Group_CNO_Sessions','_',var];

%Exclude subjects with no CNO sessions
exclIdx = cellfun(@isempty,{(subjects.testDates_0mg)}');
subjects = subjects(~exclIdx);

for i = 1:numel(subjects)
    %Aggregate data
    data{i} = [subjects(i).sessions.(var)];
    dates{i} = datetime([subjects(i).sessions.session_date]);
    
    %Find missing sessions and pad with NaN
    testDates_all = ...
        [subjects(i).testDates_0mg, subjects(i).testDates_5mg];
    missingDates = testDates_all(~ismember(testDates_all,dates{i}));
    if ~isempty(missingDates)
        disp(['Missing test dates for ' subjects(i).ID ': ' char(missingDates)]);
        for j = 1:numel(missingDates)
            data{i} = [data{i}, NaN];
            dates{i} = [dates{i}, missingDates(j)];
        end
        [dates{i}, idx] = sort(dates{i});
        data{i} = data{i}(idx);
    end
end

%Group by session order and condition
for i = 1:numel(subjects)
    % Shade according to dose of CNO:
    %   Trial 1: Veh-10-Veh-5
    %   Trial 2: Veh-5-Veh-10
    idx_0mg = ismember(dates{i}, subjects(i).testDates_0mg); % Memory-guided sessions
    idx_5mg = ismember(dates{i}, subjects(i).testDates_5mg);
      
    % Include sessions immediately preceding first test
    firstTest = find(idx_0mg|idx_5mg,1,'first');
    idx_pre = false(1,size(idx_0mg,2)); 
    idx_pre(firstTest-nPreTestSessions:firstTest-1) = true;     
    %All data in pre-, veh, 5 mg/kg and 10 mg/kg sessions
    allIdx = idx_pre | idx_0mg | idx_5mg;
    
    subj(i).sessionOrder = data{i}(allIdx)';
    doseIdx = [idx_pre; idx_0mg; idx_5mg]; %Idx for dose conditions
    for j = 1:size(doseIdx,1) % [pre, 0, 5, 10]
        subj(i).conditionMean(j,:) = mean(data{i}(doseIdx(j,:)),'omitnan');
    end
    subj(i).doseIdx = doseIdx(:,any(doseIdx)); %Truncate design matrix
end

% Verify session order across subjects 
if isequal(subj.doseIdx)
    doseIdx = subj(1).doseIdx;
else
    disp('Design matrix differs across subjects. Check any session order analyses!');
end

%Aggregate into matrix for DREADD and eYFP
plots = ["sessionOrder","conditionMean"];
for i=1:numel(plots)
    group.(plots(i)).DREADD  = [subj([subjects.dreadd]).(plots(i))];
    group.(plots(i)).eYFP  = [subj(~[subjects.dreadd]).(plots(i))];
end

%Tick Labels for Dosage
ticks.conditionMean = ["pre","0","5"];
alpha.conditionMean = [0, 0.1, 0.2];
for i = 1:numel(ticks.conditionMean)
ticks.sessionOrder(doseIdx(i,:)) = ticks.conditionMean(i);
alpha.sessionOrder(doseIdx(i,:)) = alpha.conditionMean(i);
end

grp = ["DREADD", "eYFP"];
for i = 1:numel(plots)
    figs(i) = figure('Name',join([prefix, "_", plots(i)],''));
    tiledlayout(1,2);
    colororder(cbrew.series);

    for j = 1:numel(grp)
        ax(i,j) = nexttile();     hold on;
        subj = group.(plots(i)).(grp(j));
        X = 1:size(subj,1);
        plot(subj,'.','MarkerSize',20,'LineStyle','none');
        
        %Shade bar for each condition 
        for k = 1:size(subj,1)
            Y = [0, mean(subj(k,:),'omitnan')]; %Arg 2 normally handles ylims
            p = shadeDomain( k, Y, shadeOffset, colors.(var), alpha.(plots(i))(k));
            p.EdgeColor = colors.(var);
        end
        
        switch var
            case 'pCorrect'
                %title({'Accuracy:'; grp(j)},'interpreter','none');
                ylabel('Proportion correct choices');
                ylim([0, 1]);
            case 'pOmit'
                %title({'Omitted Trials:'; grp(j)},'interpreter','none');
                ylabel('Proportion of trials');
                ylim([0, 1]);
            case 'mean_velocity'
                %title({'Forward Velocity:'; grp(j)},'interpreter','none');
                ylabel('Mean velocity (cm/s)');
            case 'nCompleted'
                %title({'Number of Trials:'; grp(j)},'interpreter','none');
                ylabel('Number of completed trials');
        end
        
        
        %Labels and titles
        xlabel('Dose CNO (mg/kg)');
        title(grp(j),'interpreter','none');
        
        %Axes ticks and scale
        ax(i,j).XTick = 1:numel(ticks.(plots(i)));
        ax(i,j).XTickLabels  = ticks.(plots(i));
        xlim([min(X)-0.5, max(X)+0.5]);
        if j~=1 %Omit axes labels
            ax(i,j).YLim = ax(i,1).YLim;
            ax(i,j).YTickLabels = [];
            ax(i,j).YLabel.Visible = 'off';
        end
        axis square;
        
    end

end


end %End main fcn

function p = shadeDomain( xVals, yLims, shadeOffset, color, transparency )

if isempty(xVals)
    return
end

%Find start and end of each block
startVal = xVals(logical([1, diff(xVals)-1]));
endVal = xVals(logical([diff(xVals)-1, 1]));

%Color patchs
for i = 1:numel(startVal)
    X = [startVal(i)-shadeOffset, endVal(i)+shadeOffset];
    X = [X, fliplr(X)];
    Y = [yLims(2),yLims(2),yLims(1),yLims(1)];
    p = patch(X, Y, color,'EdgeColor','none',...
        'FaceAlpha',transparency); hold on;
end

end