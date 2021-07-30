function figs = fig_longitudinal_trialDuration( subjects )

setup_figprops('placeholder'); %Customize for performance plots
figs = gobjects(0);

conditions = ["outcome","priorOutcome","conflict"];

%Plotting params
lineWidth = 1;
shadeOffset = 0.2;
transparency = 0.2;

%Colors
colors = setPlotColors(brewColorSwatches);
prefix = 'longitudinal_GLM';

figIdx = 1;
for i = 1:numel(subjects)
    
    trials = subjects(i).trials;
    trialData = subjects(i).trialData;
    
    
    for j = 1:numel(conditions)
        %Extract data
        switch conditions(j)
            case "outcome"
                correctIdx = cellfun(@(trialIdx,fwdIdx) trialIdx & fwdIdx,...
                    {trials.correct},{trials.forward},'UniformOutput',false);
                errorIdx = cellfun(@(trialIdx,fwdIdx) trialIdx & fwdIdx,...
                    {trials.error},{trials.forward},'UniformOutput',false);
                data.correct = cellfun(@(dur,trialIdx) dur(trialIdx),...
                    {trialData.duration},correctIdx,'UniformOutput',false);
                data.error = cellfun(@(dur,trialIdx) dur(trialIdx),...
                    {trialData.duration},errorIdx,'UniformOutput',false);
            case "priorOutcome"
                priorCorrectIdx = cellfun(@(trialIdx,fwdIdx) [false, trialIdx(1:end-1)] & fwdIdx,...
                    {trials.correct},{trials.forward},'UniformOutput',false);
                priorErrorIdx = cellfun(@(trialIdx,fwdIdx) [false, trialIdx(1:end-1)] & fwdIdx,...
                    {trials.error},{trials.forward},'UniformOutput',false);
                data.priorCorrect = cellfun(@(dur,trialIdx) dur(trialIdx),...
                    {trialData.duration},priorCorrectIdx,'UniformOutput',false);
                data.priorError = cellfun(@(dur,trialIdx) dur(trialIdx),...
                    {trialData.duration},priorErrorIdx,'UniformOutput',false);
            case "conflict"
                congruentIdx = cellfun(@(trialIdx,fwdIdx) trialIdx & fwdIdx,...
                    {trials.congruent},{trials.forward},'UniformOutput',false);
                conflictIdx = cellfun(@(trialIdx,fwdIdx) trialIdx & fwdIdx,...
                    {trials.conflict},{trials.forward},'UniformOutput',false);
                data.congruent = cellfun(@(dur,trialIdx) dur(trialIdx),...
                    {trialData.duration},congruentIdx,'UniformOutput',false);
                data.conflict = cellfun(@(dur,trialIdx) dur(trialIdx),...
                    {trialData.duration},conflictIdx,'UniformOutput',false);
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
    X = 1:numel(sessions);

        
            %Axes scale
            xlim([0, max(X)+1]);
            rng = max(cellfun(@max,data))-min(cellfun(@min,data));

    
       h = plot_basicBox( X, data, boxWidth, lineWidth, color, transparency );
        
    %Axes scale
    ax.PlotBoxAspectRatio = [3,2,1];
    xlim([0, max(X)+1]);
    ylim([min(cellfun(@min,data)),max(cellfun(@max,data))] + 0.1*rng*[-1,1]);
    legend(p,conditions,'Location','best','Interpreter','none');
    
    %Labels and titles
    xlabel('Session number');
    
    title(subjects(i).ID,'interpreter','none');
    
    %Adjust height of shading as necessary
    if numel(ax.YAxis)==2
        ax.YAxis(1).Limits = [0, max(ax.YAxis(1).Limits)]; %Set min to zero
        ax.YAxis(2).Limits = [0, max(ax.YAxis(2).Limits)];
    end
    maxY = max([ax.YAxis(1).Limits]);
    minY = min([ax.YAxis(1).Limits]);
    newVert = [maxY,maxY,minY,minY];
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