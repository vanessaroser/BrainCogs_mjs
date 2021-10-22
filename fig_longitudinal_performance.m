function figs = fig_longitudinal_performance( subjects, vars_cell, colors )

% vars = struct('pCorrect',false,'pOmit',false,'mean_velocity',false);
for i = 1:numel(vars_cell)
    vars{i} = vars_cell{i};
end

setup_figprops('placeholder'); %Customize for performance plots
figs = gobjects(0);

%Plotting params
lineWidth = 1;
shadeOffset = 0.5;
transparency = 0.1;

%Colors
cbrew = brewColorSwatches;
colors.mean_stuckTime = cbrew.orange;
colors.mean_pSkid = cbrew.orange;
colors.mean_velocity = cbrew.green;
colors.pOmit = cbrew.black;

% Plot Performance as a function of Training Day
% one panel for each subject

%Load performance data
% for the future let's parse relevant data before saving as MAT
prefix = 'Performance';

for i = 1:numel(subjects)
    %Performance as a function of training day
    figs(i) = figure(...
        'Name',join([prefix, subjects(i).ID, string(vars)],'_'));
    tiledlayout(1,1);
    ax = nexttile();
    hold on;
    
    % Shade according to different phases of training
    sessionType = [subjects(i).sessions.sessionType];
    levels = cellfun(@(L) L(end),{subjects(i).sessions.level});
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
            ylim, shadeOffset, colors.level(values(j),:), alpha);
        shading(numel(shading)+(1:numel(patches))) = patches; 
    end
    
    %Line at 0.5 for proportional quantities
    X = 1:numel(subjects(i).sessions);
    if all(ismember(vars,{'pCorrect','pCorrect_congruent','pCorrect_conflict','pOmit'}))
        plot([0,X(end)+1],[0.5, 0.5],...
            ':k','LineWidth',1);
    end
    
    yyax = {'left','right'};
    for j = 1:numel(vars)
        %Dual Y-axes or 0.5 line for proportional quantities
        if numel(vars)>1 && any(~ismember(vars,...
                {'pCorrect','pCorrect_conflict','pOmit'}))
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
                    if  ~all(isnan([subjects(i).sessions.pCorrect_conflict]))
                        legend(p,{'All','Conflict'},'Location','northwest','Interpreter','none');
                    end
                else
                    legendVars = cellfun(@(C) ~all(isnan([subjects(i).sessions.(C)])), vars);
                    legend(p,vars{legendVars},'Location','northwest','Interpreter','none');
                end
            end
        end
        
        switch vars{j}
            case {'pCorrect','pCorrect_conflict'}
                p(j).YData(sessionType=="Forced") = NaN;
                ylabel('Accuracy');
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
        end
    end
    
    
    %Axes scale
    ax.PlotBoxAspectRatio = [3,2,1];
    xlim([0, max(X)+1]);
    
    %Labels and titles
    xlabel('Session number');
    
    title(subjects(i).ID,'interpreter','none');
    
    %Add labels for maze-type/rule
    typeLabels = unique(sessionType,'stable');
    txtX = arrayfun(@(idx) find(sessionType==typeLabels(idx),1,'last'), 1:numel(typeLabels));
    txtY = min(ylim)+[1,2,1].*...
        0.1*(max(ylim)-min(ylim));
%     yyaxis left;
    for j=1:numel(typeLabels)
        txt(j) = text(txtX(j),txtY(j),typeLabels(j),...
            'Color',colors.level(levels(txtX(j)),:),...
            'HorizontalAlignment','right');
    end
    
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