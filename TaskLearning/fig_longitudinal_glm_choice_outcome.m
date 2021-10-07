function figs = fig_longitudinal_glm_choice_outcome( subjects, vars_cell, colors )

% vars = struct('pCorrect',false,'pOmit',false,'mean_velocity',false);
for i = 1:numel(vars_cell)
    vars{i} = vars_cell{i};
end

setup_figprops('placeholder'); %Customize for performance plots
figs = gobjects(0);

%Plotting params
lineWidth = 1;
shadeOffset = 0.5;
transparency = 0.2;
prefix = 'longitudinal_GLM';

for i = 1:numel(subjects)
    if isfield(subjects(i).sessions,'glm2')
        sessions = subjects(i).sessions(cellfun(@(GLM) ~isempty(GLM), {subjects(i).sessions.glm2}));
    else, continue
    end
    
    figs(i) = figure(...
        'Name',join([prefix, subjects(i).ID, string(vars)],'_'));
    tiledlayout(1,1);
    ax = nexttile();
    hold on;

    % Shade according to different phases of training
    colors.level(1:8,:) =  ones(8,3);
    sessionType = [sessions.sessionType];
    levels = cellfun(@(L) L(end),{sessions.level});
    values = unique(levels(levels>8)); %Only shade Alternation sessions
    shading = gobjects(0);
    for j = 1:numel(values)
        sameType = unique(sessionType(levels==values(j)));
        pastLevels = levels>=values(j) & sessionType==sameType; % Sessions at each level
        alpha = transparency;
        if unique(levels(sessionType==sameType))==values(j)
        	alpha = 2*transparency;
        end
        patches = shadeDomain(find(pastLevels),...
            ylim, shadeOffset, colors.level(values(j),:), alpha);
        shading(numel(shading)+(1:numel(patches))) = patches; 
    end
    
    %Performance as a function of training day
    X = 1:numel(sessions);
    for j = 1:numel(vars)
        %Extract data
        if ismember(vars{j},{'cueSide','rewChoice','unrewChoice','bias'})
            data{j} = arrayfun(@(sessionIdx) sessions(sessionIdx).glm2.(vars{j}).beta, 1:numel(sessions))';
            se = arrayfun(@(sessionIdx) sessions(sessionIdx).glm2.(vars{j}).se, 1:numel(sessions),'UniformOutput',false);
        else
            data{j} = arrayfun(@(sessionIdx) sessions(sessionIdx).glm2.(vars{j}), 1:numel(sessions));
        end
        
        if numel(vars)>1 && any(ismember(vars,{'N','conditionNum'}))
            if j==1
                yyaxis left
            else
                yyaxis right
            end
            ax.YAxis(j).Color = colors.(vars{j});
        else
            %Axes scale
            xlim([0, max(X)+1]);
            rng = max(cellfun(@max,data))-min(cellfun(@min,data));
            ylim([min(cellfun(@min,data)),max(cellfun(@max,data))] + 0.1*rng*[-1,1]);
        end
        
        if ismember(vars{j},{'cueSide','rewChoice','unrewChoice','bias'})
            for k = 1:numel(sessions)
                plot([X(k),X(k)],se{k},'color',colors.(vars{j}),'LineWidth',lineWidth);
            end
        end
        
        %Plot baseline
        if j==1
            switch vars{j}
                case 'N'
                    ylabel('Number of trials');
                case 'conditionNum'
                    ylabel('Condition number for X''X');
                case  {'R_predictors', 'R_cue_choice', 'R_priorChoice_choice'}
                    plot([0,numel(X)+1],[0, 0],'k:','LineWidth',1);   %Zero line
                    ylabel('Correlation Coef.');
                case {'pRightCue','pRightChoice'}
                    plot([0,numel(X)+1],[0.5, 0.5],'k:','LineWidth',1);   %0.5 line
                    ylabel('Proportion of trials');
                case {'cueSide','rewChoice','unrewChoice','bias'}
                    plot([0,numel(X)+1],[0, 0],'k:','LineWidth',1);   %Zero line
                    ylabel('Regression Coef.');
            end
        end
        p(j) = plot(X, data{j},'.','MarkerSize',20,'Color',colors.(vars{j}),...
            'LineWidth',lineWidth,'LineStyle','none');
    end
    
    %Simplify markers/colors for >2 vars
    symbols = {'o','^','^','_'};
    for j = 1:numel(vars)
        faceColor = {'none',colors.(vars{j}),colors.(vars{j}),'none'};
        set(p(j),'Marker',symbols{j},'MarkerSize',8,'LineWidth',lineWidth);
        %         p(j).MarkerFaceColor = faceColor{j};
        p(j).MarkerFaceColor = 'none';
    end
    
    %Axes scale
    ax.PlotBoxAspectRatio = [3,2,1];
    xlim([0, max(X)+1]);
    if ismember(vars{j},...
            {'pRightChoice','pRightCue'})
        ylim([0,1]);
    elseif ismember(vars{j},{'R_predictors', 'R_cue_choice', 'R_priorChoice_choice'})
        ylim([-1, 1]);
    elseif ismember(vars{j},{'cueSide','rewChoice','unrewChoice','bias'})
        ylim([-5, 5]);
    else
        rng = max(cellfun(@max,data))-min(cellfun(@min,data));
        ylim([min(cellfun(@min,data)),max(cellfun(@max,data))] + 0.1*rng*[-1,1]);
    end
    legend(p,vars,'Location','best','Interpreter','none');
    
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