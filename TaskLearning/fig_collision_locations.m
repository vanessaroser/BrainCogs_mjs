function figs = fig_collision_locations( subjects )

setup_figprops('placeholder'); %Customize for performance plots

%Variables to plot
axLabels = "Number of occurrences";

%Plotting params
cbrew = brewColorSwatches();
colors = struct('left', cbrew.red, 'right', cbrew.blue);
alpha = 0.1;

figs = gobjects(); %Initialize
figIdx = 0;
for i = 1:numel(subjects)
    subjID = subjects(i).ID;
    for j = 1:numel(subjects(i).sessions)
        session = subjects(i).sessions(j);
        trialData = subjects(i).trialData(j);
        trials = subjects(i).trials(j);
        logs = subjects(i).logs(j);
        %Merge blocks of same level
        mazeIdx = nan(1,numel(trials.blockIdx));
        levels = unique(session.level);
        for k = 1:numel(levels)
            %Assign unique idx to each block of trials from same maze level
            mazeIdx(ismember(trials.blockIdx,find(session.level==levels(k)))) = k;
        end
        
        for k = 1:max(mazeIdx)
            
            %Do not plot sessions with fewer than 25 included trials
            trialIdx = mazeIdx==k & trials.forward;
            nTrials = sum(~isnan(trialData.stuck_time(trialIdx)));
            if nTrials < 100
                continue
            end
            
            %Initialize figure and axes
            figIdx = figIdx+1;
            figs(figIdx) = figure('Name',join(...
                ["Stuck_locations", subjID,...
                datestr(session.session_date,'yymmdd')],'_'),...
                'Position',[10 100 500 800]);
            ax = axes();
            hold on;
            
            %Distribution of "sticky" y-positions
            versionIdx = logs.block(session.level==levels(k)).versionIndex;
            version = logs.version(versionIdx).variables;
            lCue = str2double(logs.version(versionIdx).mazes(levels(k)).variable.lCue);
            lMem = str2double(logs.version(versionIdx).mazes(levels(k)).variable.lMemory);
            mazeLen = sum([lCue,lMem,str2double(string(...
                {version.wArm, version.armBorder})).*[1,-1]]);
            
            %Indicate end of cue region
            plot([lCue,lCue],[-0.5,0.5],':','color',cbrew.gray,'LineWidth',1);
                        
            loc = [trialData.stuck_locations{trialIdx}];
            if ~isempty(loc)
                data = struct('left', loc(2, loc(1,:)< 0), 'right', loc(2, loc(1,:)> 0));
                side = ["left","right"];
                dir = [-1,1];
                for kk = 1:2
                    [counts, edges] = histcounts(data.(side(kk)),0:5:lCue);
                    X = edges(2:end)-diff(edges(1:2))/2;
                    h = bar(X, dir(kk)*counts/sum(trialIdx),...
                        'FaceColor', colors.(side(kk)), 'FaceAlpha', 0.3, 'EdgeColor', colors.(side(kk)));
                    h.BarWidth = 1;
                end                
            end
            %Plot line for 0 frequency
            plot([0,mazeLen],[0,0],'k','LineWidth',1);            
            
            view([90,-90]);
            set(ax,'XLim',[0,mazeLen],'YLim',[-0.3,0.3],...
                'Box','off','PlotBoxAspectRatio',[3,2,1]);
            
            %Annotation
            txtY = max(ylim)-0.4*diff(ylim); %for annotation
            txtX = 0.1*diff(xlim);
            if session.sessionType=="Sensory", sessionNum = j;             
            else, sessionNum = j-find([subjects(i).sessions.sessionType]=="Sensory",1,'last');
            end
            text(txtX,txtY,{...
                subjects(i).ID;...
                join([session.sessionType,sessionNum]);...
                join(["nTrials: ",num2str(nTrials)])},...
                'Interpreter','none');
            
            ylabel('Number of stuck collisions per trial');
            xlabel('Distance (cm)');
 
            if k > 1
                figs(figIdx).Name = [figs(figIdx).Name, '_block', num2str(k)];
            end
            
        end
    end
end

% function shadeTrajectoryDist( session, var, blockIdx, plotStyle, colors, alpha )
%
% choice = ["left","right"];
% for i = 1:numel(choice)
%     data = session.(choice(i)).(var)(blockIdx).(plotStyle);
%     shadeDist( data, colors.(choice(i)),alpha );
% end
%
% function shadeDist( data, color, alpha )
% nPatches = floor(size(data,2)/2);
% center = (data(:,nPatches+1));
% X = [1:length(center), length(center):-1:1];
% for i = 1:nPatches
%     Y = [data(:,i); flipud(data(:,end-i+1))];
%     fill(X,Y,color,'EdgeColor','none','FaceAlpha',alpha); hold on;
% end
% plot(1:length(center),center,'Color',color);