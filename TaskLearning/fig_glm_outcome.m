function figs = fig_glm_outcome( subjects, vars_cell )

% vars = struct('pCorrect',false,'pOmit',false,'mean_velocity',false);
for i = 1:numel(vars_cell)
    vars{i} = vars_cell{i};
end

setup_figprops('placeholder'); %Customize for performance plots
figs = gobjects(0);

%Plotting params
lineWidth = 2;
shadeOffset = 0.2;
transparency = 0.2;

%Colors
c = cbrewer('qual','Paired',10); c2 = cbrewer('qual','Set1',9);
cbrew = struct(...
    'red',c(6,:),'red2',c(5,:),'blue',c(2,:),'blue2',c(1,:),'green',c(4,:),'green2',c(3,:),...
    'purple',c(10,:),'purple2',c(9,:),'orange',c(8,:),'orange2',c(7,:),'black',[0,0,0],'gray',c2(9,:));

colors = struct(...
    'cueSide', cbrew.black, 'priorChoice', cbrew.black, 'bias', cbrew.black,...
    'R_cue_choice', cbrew.red, 'R_priorChoice_choice', cbrew.red,'R_predictors', cbrew.red,...
    'pRightCue', cbrew.red, 'pRightChoice', cbrew.red,...
    'conditionNum', cbrew.green, 'N', cbrew.black,...
    'level',[cbrew.blue; cbrew.blue; cbrew.blue; cbrew.blue; cbrew.blue; cbrew.blue; cbrew.red]);

% Plot Performance as a function of Training Day
% one panel for each subject

%Load performance data
% for the future let's parse relevant data before saving as MAT
prefix = 'GLM';

for i = 1:numel(subjects)
    
    sessions = subjects(i).sessions;
    
    figs(i) = figure(...
        'Name',join([prefix, subjects(i).ID, string(vars)],'_'));
    tiledlayout(1,1);
    ax = nexttile();
    hold on;
    
    levels = cellfun(@min,{subjects(i).sessions.level});
    values = unique(levels(isfinite(levels)));
    for j = 1:numel(values)
        pastLevels = levels >= values(j);% Sessions at each level
        shading(j) = shadeDomain(find(pastLevels),...
            ylim, shadeOffset, colors.level(values(j),:), transparency);
    end
    
    %Performance as a function of training day
    X = 1:numel(sessions);
    for j = 1:numel(vars)
        %Extract data
        if ismember(vars{j},{'cueSide','priorChoice','bias'})
            data{j} = arrayfun(@(sessionIdx) sessions(sessionIdx).glm.(vars{j}).beta, 1:numel(sessions))';
            se = arrayfun(@(sessionIdx) sessions(sessionIdx).glm.(vars{j}).se, 1:numel(sessions),'UniformOutput',false);
        else
            data{j} = arrayfun(@(sessionIdx) sessions(sessionIdx).glm.(vars{j}), 1:numel(sessions));
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
        
        if ismember(vars{j},{'cueSide','priorChoice','bias'})
            for k = 1:numel(sessions)
                plot([X(k),X(k)],se{k},'color',colors.(vars{j}));
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
                case {'cueSide','priorChoice','bias'}
                    plot([0,numel(X)+1],[0, 0],'k:','LineWidth',1);   %Zero line
                    ylabel('Regression Coef.');
            end
        end
        p(j) = plot(X, data{j},'.','MarkerSize',20,'Color',colors.(vars{j}),...
            'LineWidth',2,'LineStyle','none');
    end
     
    %Simplify markers/colors for >2 vars
    symbols = {'o','o','_'};
    for j = 1:numel(vars)
        faceColor = {colors.(vars{j}),'none','none'};
        set(p(j),'Marker',symbols{j},'MarkerSize',8,'LineWidth',1.5);
        p(j).MarkerFaceColor = faceColor{j};
    end

    %Axes scale
    xlim([0, max(X)+1]);
    if ismember(vars{j},...
            {'pRightChoice','pRightCue'})
        ylim([0,1]);
    elseif ismember(vars{j},{'R_predictors', 'R_cue_choice', 'R_priorChoice_choice'})
        ylim([-1, 1]);
    elseif ismember(vars{j},{'cueSide','priorChoice','bias'})
        ylim([-5, 5]);
    else
        rng = max(cellfun(@max,data))-min(cellfun(@min,data));
        ylim([min(cellfun(@min,data)),max(cellfun(@max,data))] + 0.1*rng*[-1,1]);
    end
    legend(p,vars,'Location','best','Interpreter','none');

    
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
    p = patch(X, Y, color,'EdgeColor','none',...
        'FaceAlpha',transparency);
end

end