function figs = fig_motorTrajectory( trajectories, plotStyle, params )

%Generate figure for last five sessions on sensory maze and first/last five memory
T = trajectories;
subjID = string(fieldnames(T));

%Variables to plot
vars = ["x_trajectory","theta_trajectory"];
axLabels = ["X-position (cm)","Theta (rad)"];

%Plotting params
cbrew = brewColorSwatches();
colors = struct('left', cbrew.red, 'right', cbrew.blue);
alpha = 0.1;

figs = gobjects(); %Initialize
figIdx = 0;
for i = 1:numel(subjID)
    
    sessions = T.(subjID(i));
    for j = 1:numel(sessions)
        
        nBlocks = numel(T.(subjID(i))(j).nLeft);
        for k = 1:nBlocks
            
            %Do not plot sessions with fewer than 10 included trials
            if T.(subjID(i))(j).nLeft(k) < 10 || T.(subjID(i))(j).nRight(k) < 10
                continue
            end
            
            for kk = 1:numel(vars)
                %Initialize figure and axes
                figIdx = figIdx+1;
                figs(figIdx) = figure('Name',join(...
                    [vars(kk),...
                    subjID(i),...
                    datestr(sessions(j).session_date,'yymmdd')],'_'),...
                    'Position',[10 100 500 800]);
                ax = axes();
                %Plot x-position & theta as function of y-position
                shadeTrajectoryDist(sessions(j),vars(kk),k,plotStyle,colors,alpha);
                mazeLen = sessions(j).maze_length(k);
                set(ax,'XLim',[0,mazeLen],'Box','off',...
                    'PlotBoxAspectRatio',[3,2,1]);
                
                if vars(kk)=="theta_trajectory"
                    set(ax,...
                        'YTick',-pi/2:pi/4:pi/2,...
                        'YTickLabel',{'-\pi/2','-\pi/4','0','\pi/4','\pi/2'},...
                        'YLim',[-pi/2,pi/2],...
                        'View',[-90,90]);
                    txtY = -0.25*diff(ylim); %for annotation
                    if isfinite(sessions(j).maxSkidAngle(k))
                        theta = sessions(j).maxSkidAngle(k)*pi;
                        plot([0,mazeLen],[theta,theta],'LineStyle',':','color',cbrew.gray);
                        plot([0,mazeLen],[-theta,-theta],'LineStyle',':','color',cbrew.gray);
                    end
                    
                else
                    view([90,-90]);
                    ax.YLim = [-4,4];
                    txtY = 0.25*diff(ylim); %for annotation
                end
                ylabel(axLabels(kk));
                xlabel('Distance (cm)');
                
                %Annotate
                if params.annotation
                    txtX = sessions(j).maze_length(k)/4;
                    fontsize = 8;
                    sessionNum = find(...
                        [T.(subjID(i)).session_date]==(sessions(j).session_date));
                    entry(1) = string(['Session ', num2str(sessionNum)]);
                    fields = ["level","maze_length","maxSkidAngle","nLeft","nRight"];
                    for ii = 1:numel(fields)
                        entry(ii+1) = string([fields{ii},': ',num2str(sessions(j).(fields{ii})(k))]);
                    end
                    text(txtX,txtY,entry,'FontSize',fontsize,'Interpreter','none');
                end
                
                if nBlocks>1
                    figs(figIdx).Name = [figs(figIdx).Name, '_block', num2str(k)];
                end
                %title(join([subjID(i),": ",string(sessions(k).session_date)],''),'Interpreter','none');
            end
            
            
        end
    end
end

function shadeTrajectoryDist( session, var, blockIdx, plotStyle, colors, alpha )

choice = ["left","right"];
for i = 1:numel(choice)
    data = session.(choice(i)).(var)(blockIdx).(plotStyle);
    shadeDist( data, colors.(choice(i)),alpha );
end

function shadeDist( data, color, alpha )
nPatches = floor(size(data,2)/2);
center = (data(:,nPatches+1));
X = [1:length(center), length(center):-1:1];
for i = 1:nPatches
    Y = [data(:,i); flipud(data(:,end-i+1))];
    fill(X,Y,color,'EdgeColor','none','FaceAlpha',alpha); hold on;
end
plot(1:length(center),center,'Color',color);