function figs = fig_longitudinal_trialDuration( subjects, experiment )

setup_figprops('placeholder'); %Customize for performance plots
figs = gobjects(0);

conditions = ["outcome","priorOutcome","conflict","ITI"];

%Plotting params
lineWidth = 1;
boxWidth = 0.3;
shadeOffset = 0.2;
transparency = 0.2;

%Colors
colors = setPlotColors(brewColorSwatches,experiment);
prefix = 'trialDuration';

figIdx = 1;
for i = 1:numel(subjects)

    trials = subjects(i).trials;
    trialData = subjects(i).trialData;
    trialTypes = ["correct","error","congruent","conflict"];
    for j = 1:numel(trialTypes)
        idx.(trialTypes(j)) = cellfun(@(trialIdx,fwdIdx)...
            trialIdx & fwdIdx,...
            {trials.(trialTypes(j))},{trials.forward},'UniformOutput',false);
    end
    idx.priorCorrect = cellfun(@(trialIdx,fwdIdx,correctIdx)...
        [false, trialIdx(1:end-1)] & fwdIdx & correctIdx,...
        {trials.correct},{trials.forward},idx.correct,'UniformOutput',false);
    idx.priorError = cellfun(@(trialIdx,fwdIdx,correctIdx)...
        [false, trialIdx(1:end-1)] & fwdIdx & correctIdx,...
        {trials.error},{trials.forward},idx.correct,'UniformOutput',false);

    for j = 1:numel(conditions)
        %Extract data
        switch conditions(j)
            case "outcome"
                labels = ["correct","error"];
                data{1} = cellfun(@(dur,trialIdx) dur(trialIdx),...
                    {trialData.response_time},idx.correct,'UniformOutput',false);
                data{2} = cellfun(@(dur,trialIdx) dur(trialIdx),...
                    {trialData.response_time},idx.error,'UniformOutput',false);
            case "priorOutcome" %**Include only correct trials??
                labels = ["priorCorrect","priorError"];
                data{1} = cellfun(@(dur,trialIdx) dur(trialIdx),...
                    {trialData.response_time},idx.priorCorrect,'UniformOutput',false);
                data{2} = cellfun(@(dur,trialIdx) dur(trialIdx),...
                    {trialData.response_time},idx.priorError,'UniformOutput',false);
            case "conflict"
                labels = ["congruent","conflict"];
                data{1} = cellfun(@(dur,trialIdx) dur(trialIdx),...
                    {trialData.response_time},idx.congruent,'UniformOutput',false);
                data{2} = cellfun(@(dur,trialIdx) dur(trialIdx),...
                    {trialData.response_time},idx.conflict,'UniformOutput',false);
            case "ITI"
                labels = ["correct","error"];
                data{1} = cellfun(@(dur,respTime,trialIdx) dur(trialIdx)-respTime(trialIdx),...
                    {trialData.duration},{trialData.response_time},idx.correct,'UniformOutput',false);
                data{2} = cellfun(@(dur,respTime,trialIdx) dur(trialIdx)-respTime(trialIdx),...
                    {trialData.duration},{trialData.response_time},idx.error,'UniformOutput',false);
        end


        figs(figIdx) = figure(...
            'Name',join([prefix, subjects(i).ID, string(conditions(j))],'_'));
        tiledlayout(1,1);
        ax = nexttile();
        hold on;

        levels = cellfun(@min,{subjects(i).sessions.level});
        values = unique(levels(isfinite(levels)));
        for k = 1:numel(values)
            pastLevels = levels >= values(k);% Sessions at each level
            shading(k) = shadeDomain(find(pastLevels),...
                ylim, shadeOffset, colors.level(values(k),:), transparency);
        end

        %Performance as a function of training day
        X = 1:numel(trialData);
        for k = 1:numel(data) %eg correct vs. error
            for kk = X
                p(k) = plot_basicBox( X(kk), data{k}{kk}, boxWidth, lineWidth, colors.trialTypes.(labels{k}), transparency );
            end
        end

        %Axes scale
        ax.PlotBoxAspectRatio = [3,2,1];
        %Axes scale
        rng = [min(cellfun(@(C) prctile(C,9),[data{:}])), max(cellfun(@(C) prctile(C,91),[data{:}]))];
        xlim([0, max(X)+1]);
        %     ylim(rng + 0.1*rng.*[-1,1]);
        ylim([0 15]);
        if conditions(j)=="ITI"
            ylabel('Intertrial Interval (s)');
        else
            ylabel('Time to goal box (s)');
        end
        legend(p,labels,'Location','best','Interpreter','none');

        %Labels and titles
        xlabel('Session number');

        title(subjects(i).ID,'interpreter','none');

        %Adjust height of shading as necessary
        maxY = max(ylim);
        minY = min(ylim);
        newVert = [max(ylim), max(ylim), min(ylim), min(ylim)];
        for j = 1:numel(shading)
            shading(j).Vertices(:,2) = newVert;
        end
        clearvars shading
        figIdx = figIdx+1;
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
        'FaceAlpha',transparency);
end

end