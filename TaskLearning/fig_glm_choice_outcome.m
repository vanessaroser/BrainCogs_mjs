function figs = fig_glm_choice_outcome( subjects, glmName )

setup_figprops('placeholder'); %Customize for performance plots
figs = gobjects(0);

%Plotting params
lineWidth = 2;

%Colors
c = cbrewer('qual','Paired',10); c2 = cbrewer('qual','Set1',9);
cbrew = struct(...
    'red',c(6,:),'red2',c(5,:),'blue',c(2,:),'blue2',c(1,:),'green',c(4,:),'green2',c(3,:),...
    'purple',c(10,:),'purple2',c(9,:),'orange',c(8,:),'orange2',c(7,:),...
    'black',[0,0,0],'gray',c2(9,:),'pink',c2(8,:));

colors = struct('bias', cbrew.black,'cueSide',cbrew.black,'rewChoice', cbrew.green,'unrewChoice', cbrew.pink);

% Plot Beta(choice(n-i)) separately for rewarded and unrewarded choices
% one panel for each subject

figIdx = 1;
for i = 1:numel(subjects)
    for j = 1:numel(subjects(i).sessions)
        S = subjects(i).sessions(j);

        if isempty(S.(glmName)), continue, end

        figs(figIdx) = figure(...
            'Name',join([glmName, subjects(i).ID, datestr(S.session_date,'yymmdd')],'_'));
        tiledlayout(1,1);
        ax = nexttile();
        hold on;
        
        %B==0 line
        plot([0,numel(S.(glmName).rewChoice.beta)+3],[0,0],':k','LineWidth',1);
        %Bias & Cue Side
        term = {'bias','cueSide'};
        maxY = 0;
        for k=1:2
            data = S.(glmName).(term{k});
            plot([k,k],data.se,'Color',colors.(term{k}),'LineWidth',lineWidth);
            plot(k,data.beta,'o','Color',colors.(term{k}),'MarkerFaceColor',colors.(term{k}),...
                'MarkerSize',10,'MarkerFaceColor',colors.(term{k}),'LineStyle','-','LineWidth',lineWidth);
            maxY = max([maxY;abs(data.beta)]);
        end
        %Choice History
        term = {'rewChoice','unrewChoice'};
        for k=1:numel(term)
            data = S.(glmName).(term{k});
            for kk = 1:size(data.se,2)
                X = [kk+2, kk+2];
                plot(X,data.se(:,kk),'Color',colors.(term{k}),'LineStyle','-','LineWidth',lineWidth);
            end
            X = (1:numel(data.beta))+2;
            p(k) = plot(X,data.beta,'o','Color',colors.(term{k}),...
                'MarkerSize',10,'MarkerFaceColor',colors.(term{k}),'LineStyle','-','LineWidth',lineWidth);
            maxY = max([maxY,abs(data.beta)]);
        end
        legend(p,term,'Location','best','Interpreter','none');
        
        %Axes formatting
        title(string(subjects(i).sessions(j).session_date));
        ax.PlotBoxAspectRatio = [3,2,1];
        ax.XTick = 1:numel(data.beta)+2;
        ticklabels = {'Bias','Cue','C(n-1)','C(n-2)','C(n-3)','C(n-4)','C(n-5)'};
        ax.XTickLabel = ticklabels(1:numel(data.beta)+2);
        ax.XTickLabelRotation = 22;
        ylabel('Regression Coefficient');
        xlabel('Predictor');

        maxY = max([maxY,1]);
        ylim(1.2*[-maxY,maxY]);
        xlim([0,numel(data.beta)+3]);
        
        figIdx = figIdx+1;
    end
end