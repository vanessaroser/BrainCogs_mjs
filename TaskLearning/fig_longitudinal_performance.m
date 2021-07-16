function figs = fig_longitudinal_performance( subjects, vars_cell )

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

colors = struct('pCorrect', cbrew.black, 'pOmit', cbrew.orange, 'mean_pSkid', cbrew.orange, 'pStuck', cbrew.orange,...
    'mean_stuckTime', cbrew.orange, 'mean_velocity', cbrew.green, 'nCompleted', cbrew.black,...
    'betaCues', cbrew.black, 'betaChoice', cbrew.black,...
    'level',[cbrew.blue; cbrew.blue; cbrew.blue; cbrew.blue; cbrew.blue; cbrew.blue; cbrew.red]); 

% Plot Performance as a function of Training Day
% one panel for each subject

%Load performance data
% for the future let's parse relevant data before saving as MAT
prefix = 'Performance';

for i = 1:numel(subjects)
    
    figs(i) = figure(...
        'Name',join([prefix, subjects(i).ID, string(vars)],'_'));
    tiledlayout(1,1);
    ax(i) = nexttile();
    hold on;
    
        % Shade according to different phases of training
%     values = [subjects(i).sessions.maxSkidAngle];
%     values = unique(values(isfinite(values)));
%     for j = 1:numel(values)
%         maxAngleSessions = ... % Sessions at each max skid angle
%             cellfun(@min,{subjects(i).sessions.maxSkidAngle}) <= values(j);
%         shadeDomain(find(maxAngleSessions),...
%             [0,1], shadeOffset, cbrew.orange, transparency);
%     end
    levels = cellfun(@min,{subjects(i).sessions.level});
    values = unique(levels(isfinite(levels)));
    for j = 1:numel(values)
        pastLevels = levels >= values(j);% Sessions at each level
        shading(j) = shadeDomain(find(pastLevels),...
            ylim, shadeOffset, colors.level(values(j),:), transparency);
    end
    
    %Performance as a function of training day
    X = 1:numel(subjects(i).sessions);
    for j = 1:numel(vars)
        
        if numel(vars)>1 && any(~ismember(vars,{'pCorrect','pOmit','betaCues','betaChoice'}))
            if j==1
                yyaxis left
            else 
                yyaxis right
            end
            ax(i).YAxis(j).Color = colors.(vars{j});
        end
        
        p(j) = plot(X, [subjects(i).sessions.(vars{j})],...
            '.','MarkerSize',20,'Color',colors.(vars{j}),...
            'LineWidth',2,'LineStyle','none');
        if j>1 && isequal(colors.(vars{j}),colors.(vars{j-1}))
            set(p,'Marker','o','MarkerSize',8,'LineWidth',1.5);
            p(1).MarkerFaceColor = colors.(vars{j});
            p(2).MarkerFaceColor = 'none';
            legend(p,{vars{j-1},vars{j}},'Location','northwest');
        end
    
        switch vars{j}
            case 'pCorrect'
                ylabel('Accuracy');
                ylim([0, 1]);
            case {'pOmit','pStuck'}
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
            case {'betaCues', 'betaChoice'}
                pred = {'cueSide','priorChoice','bias'};
                beta = {'betaCues','betaChoice','bias'};
                for k=1:numel(subjects(i).sessions)
                    se = subjects(i).sessions(k).glm.(pred{strcmp(beta,vars{j})}).se;
                    plot([X(k),X(k)],se,'color',colors.(vars{j}));
                end
                if j>1
                    ylabel('Regression Coef.');
                    set(p,'Marker','o','MarkerSize',8,'LineWidth',1.5);
                    p(1).MarkerFaceColor = colors.(vars{j});
                    p(2).MarkerFaceColor = 'none';
                    legend(p,{'Cues','Prior choice'},'Location','northwest');
                end
        end
    end
    
   
    %Axes scale
    xlim([0, max(X)+1]);
    
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