function figs = fig_longitudinal_glm( subjects, vars_cell )

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
    'conditionNum', cbrew.green, 'N', cbrew.green,...
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
    ax(i) = nexttile();
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
        
        %         if numel(vars)>1 && any(ismember(vars,{'pCorrect','pOmit','betaCues','betaChoice'}))
        %             if j==1
        %                 yyaxis left
        %             else
        %                 yyaxis right
        %             end
        %             ax(i).YAxis(j).Color = colors.(vars{j});
        %         end
        %Extract data
        if ismember(vars{j},{'cueSide','priorChoice','bias'})
            data{j} = arrayfun(@(sessionIdx) sessions(sessionIdx).glm.(vars{j}).beta, 1:numel(sessions))';
            se = arrayfun(@(sessionIdx) sessions(sessionIdx).glm.(vars{j}).se, 1:numel(sessions),'UniformOutput',false);
        else
            data{j} = arrayfun(@(sessionIdx) sessions(sessionIdx).glm.(vars{j}), 1:numel(sessions));
        end
        
        p(j) = plot(X, data{j},'.','MarkerSize',20,'Color',colors.(vars{j}),...
            'LineWidth',2,'LineStyle','none');
        
        switch vars{j}
            case {'N','conditionNum'}
                ylabel('Number of trials');
            case  {'R_predictors', 'R_cue_choice', 'R_priorChoice_choice'}
                 ylabel('Correlation Coef.');
            case {'pRightCue','pRightChoice'}
                ylabel('Proportion of trials');
            case {'cueSide','priorChoice','bias'}
                for k = 1:numel(sessions)
                    plot([X(k),X(k)],se{k},'color',colors.(vars{j}));
                end
                ylabel('Regression Coef.'); 
        end
    end
    symbols = {'o','o','^'};
    faceColor = {colors.(vars{j}),'none',colors.(vars{j})};
    for j = 1:numel(vars)
        set(p(j),'Marker',symbols{j},'MarkerSize',8,'LineWidth',1.5);
        p(j).MarkerFaceColor = faceColor{j};
    end
    
    %Axes scale
    xlim([0, max(X)+1]);
    rng = max(cellfun(@max,data))-min(cellfun(@min,data));
    ylim([min(cellfun(@min,data)),max(cellfun(@max,data))] + 0.1*rng*[-1,1]);
    legend(p,vars,'Location','northwest','Interpreter','none');
    
    %Labels and titles
    xlabel('Session number');
    
    title(subjects(i).ID,'interpreter','none');
    
    %Adjust height of shading as necessary
    newVert = [max(ylim(ax(1))),max(ylim(ax(1))),min(ylim(ax(1))),min(ylim(ax(1)))];
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