function figs = fig_periswitch_mem( subjects, var )

setup_figprops('placeholder'); %Customize for performance plots

%Plotting params
lineWidth = 2;
shadeOffset = 0.5;
transparency = 0.2;

%Colors
cbrew = brewColorSwatches();
colors = struct('pCorrect', cbrew.blue, 'pOmit', cbrew.orange, 'mean_velocity',...
    cbrew.green, 'nCompleted', cbrew.black);

%Prefix for save
prefix = 'Group_';

%Aggregate data
for i = 1:numel(subjects)
    
    % Shade according to different phases of training
    memIdx = ... % Memory-guided sessions
        cellfun(@min,{subjects(i).sessions.level}) >= 5;
    longIdx = ...     % Sessions after cue region extended to 200 cm
        datetime({subjects(i).sessions.session_date}) >= datetime('2021-04-12') & memIdx;
    exclIdx = diff([memIdx,1])==-1 | isnan([subjects(i).sessions.pCorrect]); %Exclude isolated mem sessions and sessions with no trials
    
    longCueSessions{i} = longIdx & memIdx & ~exclIdx;     % Sessions after cue region extended to 200 cm
    memSessions{i} = memIdx & ~longIdx & ~exclIdx; % Memory-guided sessions before switch to long cue
    preMemSessions{i} = ~memIdx & ~exclIdx;
end
subjIdx = find(cellfun(@any,memSessions)); %Exclude if no mem sessions pre-switch to long cue

%Find minimum number of sessions pre-switch with all subjects
nSessionsPreMem = min(cellfun(@sum,preMemSessions(subjIdx)));
nSessionsMem = min(cellfun(@sum,memSessions(subjIdx)));
nSessionsLongCue = min(cellfun(@sum,longCueSessions(subjIdx)));

%Aggregate into matrix
for i = 1:numel(subjIdx)
    memIdx = {...
        find(preMemSessions{subjIdx(i)},nSessionsPreMem,'last'),...
        find(memSessions{subjIdx(i)},nSessionsMem,'first')};
    longCueIdx = {...
        find(memSessions{subjIdx(i)},nSessionsMem,'last'),...
        find(longCueSessions{subjIdx(i)},nSessionsLongCue,'first')};
        values = [subjects(subjIdx(i)).sessions.(var)];
        group.(var).introMem{1}(i,:) = values(memIdx{1});
        group.(var).introMem{2}(i,:) = values(memIdx{2});
        group.(var).introLongCue{1}(i,:) = values(longCueIdx{1});
        group.(var).introLongCue{2}(i,:) = values(longCueIdx{2});
end

plots = {'introMem','introLongCue'};
titles = {...
    'Sensory to Memory';...
    'Extend Cue Region'};
shading = {cbrew.blue,cbrew.gray};
for i = 1:numel(plots)
    
    figs(i) = figure(...
        'Name',join([prefix, plots{i}, '_', var],''));
    tiledlayout(1,1);
    colororder(cbrew.series);
    ax(i) = nexttile();
    hold on;
    

    data = group.(var).(plots{i});
    X = -(size(data{1},2)) : size(data{2},2)-1;
    shadeDomain(X(X>=0),... %Shade sessions after switch
        [0,1], shadeOffset, shading{i}, 0.2);
    plot(X, [data{:}],'.','MarkerSize',10,'LineStyle','none');
    
    
    plot(X(X<0), mean([data{1}],'omitnan'),'Color',colors.(var));
    plot(X(X>=0), mean([data{2}],'omitnan'),'Color',colors.(var));
        
        switch var
            case 'pCorrect'
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
    title(titles{i},'interpreter','none');
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