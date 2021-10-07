function fig = fig_periswitch_sensory( subjects, var )

setup_figprops('placeholder'); %Customize for performance plots

%Plotting params
markerSize = [10,6];
lineWidth = 1;
shadeOffset = 0.5;
transparency = 0.3;

%Colors
cbrew = brewColorSwatches;
colors.pCorrect = cbrew.black; %Contrast for pCorrect
colors.pCorrect_congruent = cbrew.black; %Contrast for pCorrect
colors.pCorrect_conflict = cbrew.red; %Contrast for pCorrect
colors.pOmit = cbrew.orange;
colors.nCompleted = cbrew.blue;
colors.mean_velocity = cbrew.green; 


%Prefix for save
prefix = 'Group_';

%Aggregate data
nSensory = 10;
nEarly = 10;
nLate = 10;
for i = 1:numel(subjects)
    % Group according to different phases of training
    forcedIdx = ... % Forced-choice sessions
        cellfun(@max,{subjects(i).sessions.level}) < 7;
    sensoryIdx = ~forcedIdx &... % Sensory-guided sessions
        cellfun(@max,{subjects(i).sessions.level}) < 9;
    sensorySessions{i} = find(sensoryIdx,nSensory,'last');
    altSessions{i} = find(altIdx);
    earlySessions{i} = find(altIdx,nEarly,'first'); 
    lateSessions{i} = find(altIdx,nLate,'last');
end
maxSessions = mode(cellfun(@numel,altSessions));

%Aggregate into matrix

Title = 'Sensory to Alternation';
shading = cbrew.blue;
    
    fig = figure('Name',join([prefix,'_', var],''));
    colororder(cbrew.series);
    ax = axes();
    hold on;

    data = getData(subjects,var,sensorySessions,altSessions,nSensory,maxSessions);
    X = -(size(data{1},2)) : size(data{2},2)-1;
    shadeDomain(X(X>=0),... %Shade sessions after switch
        [0,1], shadeOffset, shading, transparency);
    
    if var=="pCorrect_conflict"
        plot(X, mean([data{:}],'omitnan'),'o','MarkerSize',markerSize(2),...
            'LineStyle','none','LineWidth',lineWidth,'Color',colors.(var));
        plotSEM(X, [data{:}],colors.(var),lineWidth);
        var = "pCorrect_congruent";
        data = getData(subjects,var,sensorySessions,altSessions,nSensory,maxSessions); %Co-plot with pCorrect_congruent
        plot(X, mean([data{:}],'omitnan'),'o','MarkerSize',markerSize(2),...
            'LineStyle','none','LineWidth',lineWidth,'Color',colors.(var));
        plotSEM(X, [data{:}],colors.(var),lineWidth);
    else
        plot(X, [data{:}],'.','MarkerSize',markerSize(1),'LineStyle','none');
        plot(X(X<0), mean([data{1}],'omitnan'),'Color',colors.(var));
        plot(X(X>=0), mean([data{2}],'omitnan'),'Color',colors.(var));
    end
        switch var
            case {'pCorrect', 'pCorrect_conflict'}
                ylabel('Accuracy');
                ylim([0, 1]);
            case 'pOmit'
                ylabel('Proportion of trials');
                ylim([0, 1]);
            case 'mean_velocity'
                ylabel('Mean velocity (cm/s)');
            case 'nCompleted'
                ylabel('Number of completed trials');
        end
    
    %Axes scale
    xlim([min(X)-0.5, max(X)+0.5]);
    axis square;
    
    %Labels and titles
    xlabel('Sessions from introduction');
    title(Title,'interpreter','none');
end
%End main fcn

    function data = getData(subjects,var,sensorySessions,altSessions,nSensory,maxSessions)
        data = {NaN(numel(subjects),nSensory), NaN(numel(subjects),maxSessions)};
        for i = 1:numel(subjects)
            values = [subjects(i).sessions.(var)];
            data{1}(i,:) = values(sensorySessions{i});
            data{2}(i,1:min(numel(altSessions{i}),maxSessions)) =...
                values(altSessions{i}(1:min(numel(altSessions{i}),maxSessions)));
        end
    end
    
    function plotSEM(X,data,color,lineWidth)
    sem = std(data,'omitnan')./sqrt(sum(~isnan(data)));
    sem = mean(data,'omitnan') + [-1;1].*sem;
    for i = 1:numel(X)
        plot([X(i),X(i)],sem(:,i),'Color',color,'LineWidth',lineWidth);
    end
    end

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