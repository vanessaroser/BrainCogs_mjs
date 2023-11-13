function figs = fig_longitudinal_performance( subjects, vars_cell, colors )

for i = 1:numel(vars_cell)
    vars{i} = vars_cell{i};
end

setup_figprops('placeholder'); %Customize for performance plots
figs = gobjects(0);

%Plotting params
lineWidth = 1;
shadeOffset = 0.5;
transparency = 0.1;

% Plot Performance as a function of Training Day
% one panel for each subject

%Load performance data
prefix = 'Performance';

for i = 1:numel(subjects)
    %Performance as a function of training day
    figs(i) = figure(...
        'Name',join([prefix, subjects(i).ID, string(vars)],'_'));
    tiledlayout(1,1);
    ax = nexttile();
    hold on;

    % Shade according to different phases of training
    sessionType = [subjects(i).sessions.taskRule];
    levels = cellfun(@(L) L(end),{subjects(i).sessions.level});
    levels(sessionType=="alternation")=98; %**TEMPORARY for mixed Alt/Tactile/Vis cohort
    levels(sessionType=="visual" & levels==6)=99; %**TEMPORARY for mixed Alt/Tactile/Vis cohort
    values = unique(levels);
    shading = gobjects(0);
    for j = 1:numel(values)
        sameType = unique(sessionType(levels==values(j)));
        pastLevels = levels>=values(j) & sessionType==sameType;% Sessions at each level
        alpha = transparency;
        if unique(levels(sessionType==sameType))==values(j)
            alpha = 2*transparency;
        end
        patches = shadeDomain(find(pastLevels),...
            ylim, shadeOffset, colors.taskRule.(sameType), alpha);
        shading(numel(shading)+(1:numel(patches))) = patches;
    end

    %Line at 0.5 for proportional quantities
    allProportional = all(ismember(vars,{'pCorrect','pCorrect_congruent','pCorrect_conflict','pOmit',...
        'maxCorrectMoving','maxCorrectMoving_congruent','maxCorrectMoving_conflict','bias'}));
    X = 1:numel(subjects(i).sessions);
    if allProportional
        plot([0,X(end)+1],[0.5, 0.5],...
            ':k','LineWidth',1);
        %Overall mean for congruent & conflict plots
        if isequal(vars,{'maxCorrectMoving_congruent','maxCorrectMoving_conflict'})
            p(3) = plot(X, [subjects(i).sessions.maxCorrectMoving],...
                'Color',[0.8,0.8,0.8],'LineWidth',3);
        end
    end
    if ismember(vars,{'pCorrect','pCorrect_congruent','pCorrect_conflict','bias'})
        plot([0,X(end)+1],[0.8, 0.8],':k','LineWidth',1); %Threshold correct rate
        plot([0,X(end)+1],[0.1, 0.1],':k','LineWidth',1); %Threshold bias
    end

    yyax = {'left','right'};
    for j = 1:numel(vars)
        %Dual Y-axes
        if numel(vars)>1 && ~allProportional
            yyaxis(ax,yyax{j});
            ax.YAxis(j).Color = colors.(vars{j});
        end

        p(j) = plot(X, [subjects(i).sessions.(vars{j})],...
            '.','MarkerSize',20,'Color',colors.(vars{j}),...
            'LineWidth',lineWidth,'LineStyle','none');

        marker = {'o','o','_'};
        faceColor = {colors.(vars{j}),'none','none'};
        if numel(vars)>1 %&& isequal(colors.(vars{j}),colors.(vars{j-1}))
            set(p(j),'Marker',marker{j},...
                'MarkerSize',8,...
                'MarkerFaceColor',faceColor{j},...
                'LineWidth',lineWidth);
            if j==numel(vars)
                if isequal(vars,{'pCorrect','pCorrect_conflict'})
                    legend(p,{'All','Conflict'},'Location','best','Interpreter','none');
                elseif isequal(vars,{'pCorrect_congruent','pCorrect_conflict'})
                    legend(p,{'Congruent','Conflict'},'Location','best','Interpreter','none');
                elseif isequal(vars,{'maxCorrectMoving_congruent','maxCorrectMoving_conflict'})
                    legend(p,{'Congruent','Conflict','All'},'Location','best','Interpreter','none');
                else
                    legendVars = cellfun(@(C) ~all(isnan([subjects(i).sessions.(C)])), vars);
                    legend(p,vars{legendVars},'Location','best','Interpreter','none');
                end
            end
        end

        switch vars{j}
            case 'pCorrect'
                ylabel('Accuracy');
                ylim([0, 1]);
            case {'pCorrect_conflict','pCorrect_congruent'}
                %Only applies to Sensory and Alternation Sessions
                p(j).YData(sessionType=="forcedChoice") = NaN;
                ylabel('Accuracy');
                ylim([0, 1]);
            case {'maxCorrectMoving','maxCorrectMoving_congruent','maxCorrectMoving_conflict'}
                %Only applies to Sensory and Alternation Sessions
                p(j).YData(sessionType=="forcedChoice") = NaN;
                ylabel('Max. Accuracy');
                ylim([0, 1]);
            case {'pOmit','pConflict','pStuck'}
                ylabel('Proportion of trials');
                ylim([0, 1]);
            case 'mean_velocity'
                ylabel('Mean velocity (cm/s)');
            case 'mean_stuckTime'
                ylabel('Proportion of time spent stuck');
                ylim([0, 1]);
            case 'mean_pSkid'
                ylabel('Proportion of maze spent skidding');
                ylim([0, 1]);
            case 'nCompleted'
                ylabel('Number of completed trials');
            case 'bias'
                %p(j).YData(sessionType=="forcedChoice") = NaN; %Only for Sensory or Alternation
                %Symbols for left and right
                p(j).Marker = 'none';
                scatter(X(p(j).YData<0),abs(p(j).YData(p(j).YData<0)),...
                    '<','MarkerFaceColor','none','MarkerEdgeColor',p(j).Color);
                scatter(X(p(j).YData>0),p(j).YData(p(j).YData>0),...
                    '>','MarkerFaceColor','none','MarkerEdgeColor',p(j).Color);
                ylabel('Bias');
                %                 legend(p); %Only include the specified variables in legend
        end
    end

    %Mark transition session for RotationsPerRev
    [ ~, changePt ] = getRotationsPerRev(subjects(i).logs);
    plot(changePt,0,'k+');

    %Only include the specified variables in legend
    legend(p);

    %Cutoff L-maze data
    zoom2TMaze = false; %Cutoff L-maze data
    if all(ismember(vars,{'pCorrect','pCorrect_conflict','pCorrect_congruent',...
            'maxCorrectMoving','maxCorrectMoving_congruent','maxCorrectMoving_conflict'}))
        zoom2TMaze = true;
        sessionType(sessionType=="forcedChoice") = "";
    end

    %Axes scale
    ax.PlotBoxAspectRatio = [3,2,1];
    xlim([0, max(X)+1]);
    if zoom2TMaze
        if sessionType=="", continue %No T-maze sessions
        else
            xlim([find(ismember(sessionType,["visual","tactile","sensory","alternation"]),1,'first')-shadeOffset,...
                max(xlim)]);
        end
    end

    %Labels and titles
    xlabel('Session number');

    title(subjects(i).ID,'interpreter','none');

    %Add labels for maze-type/rule
    typeLabels = unique(sessionType,'stable');
    typeLabels = typeLabels(typeLabels~="");
    txtX = arrayfun(@(idx) find(sessionType==typeLabels(idx),1,'first'), 1:numel(typeLabels));
    txtY = min(ylim)+(1:numel(typeLabels)).*0.05*(max(ylim)-min(ylim));
    %     yyaxis left;
    txt = gobjects(numel(typeLabels),1);
    for j = 1:numel(typeLabels)
        txt(j) = text(txtX(j),txtY(j),typeLabels(j),...
            'Color',colors.taskRule.(typeLabels(j)),...
            'HorizontalAlignment','left');
    end
    txt(end).HorizontalAlignment='right';
    txt(end).Position(1) = find(sessionType==typeLabels(end),1,'last');

    %Adjust height of shading as necessary
    newVert = [max([ax.YAxis.Limits]),max([ax.YAxis.Limits]),min([ax.YAxis.Limits]),min([ax.YAxis.Limits])]; %Might need ax.YAxis(i).Limits...
    for j = 1:numel(shading)
        shading(j).Vertices(:,2) = newVert;
    end
    clearvars shading
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
    p(i) = patch(X, Y, color,'EdgeColor','none',...
        'FaceAlpha',transparency);
end

end