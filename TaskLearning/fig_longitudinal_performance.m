function figs = fig_longitudinal_performance( subjects, varargin )

% vars = struct('pCorrect',false,'pOmit',false,'mean_velocity',false);
for i=1:numel(varargin)
    vars{i,1} = varargin{i};
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

colors = struct('pCorrect', cbrew.blue, 'pOmit', cbrew.orange, 'mean_velocity', cbrew.green, 'nCompleted', cbrew.black); 

% Plot Performance as a function of Training Day
% one panel for each subject

%Load performance data
% for the future let's parse relevant data before saving as MAT
prefix = 'Performance_';

for i = 1:numel(subjects)
    
    figs(i) = figure(...
        'Name',[prefix, subjects(i).ID, '_', strjoin(vars,'_')]);
    tiledlayout(1,1);
    ax(i) = nexttile();
    hold on;
    
    % Shade according to different phases of training
    memSessions = ... % Memory-guided sessions
        cellfun(@min,{subjects(i).sessions.level}) >= 5; 
    longCueSessions = ...     % Sessions after cue region extended to 200 cm
        datetime({subjects(i).sessions.session_date}) >= datetime('2021-04-12');    
   
    shadeDomain(find(memSessions),...
        [0,1], shadeOffset, cbrew.blue, 0.2);
    shadeDomain(find(longCueSessions),...
        [0,1], shadeOffset, cbrew.gray, 0.3);      
 
    %Performance as a function of training day
    X = 1:numel(subjects(i).sessions);
    for j = 1:numel(vars)
        
        if numel(vars)>1 && any(~ismember(vars,{'pCorrect','pOmit'}))
            if j==1
                yyaxis left
            else 
                yyaxis right
            end
            ax(i).YAxis(j).Color = colors.(vars{j});
        end
        
         plot(X, [subjects(i).sessions.(vars{j})],...
                    '.','MarkerSize',20,'Color',colors.(vars{j}),'LineStyle','none');
        
        switch vars{j}
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
    end
    
   
    %Axes scale
    xlim([0, max(X)+1]);
    
    %Labels and titles
    xlabel('Session number');

    title(subjects(i).ID,'interpreter','none');

    %Legend
    
    
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