function figs = fig_longitudinal_glm_heatmap(subjects)

lineWidth = 1;
clims = [-5,5];
%Image autocorrelation of choice vector
for i = 5%1:numel(subjects)
    %Populate matrix with autocorrelations from each session
    S = subjects(i).sessions;
    fields = ["bias","cueSide","rewChoice","unrewChoice"];
    for j=1:numel(fields)
        for k=1:numel(S)
            P.(fields(j))(k,:) = S(k).glm3.(fields(j)).beta;
        end
    end
    
    prefix = "longitudinal_glm_heatmap";
    figs(i) = figure('Name',join([prefix,subjects(i).ID],'_'));%,'Position',[100 100 500 800]);
    
    nBack = size(P.rewChoice,2);
    nCol = numel(fields) + 2*(nBack-1);
    tiledlayout(1,nCol,'TileSpacing','none','Padding','none');
    
    %Line for first alternation session
    firstAltSession = find([S.sessionType]=="Alternation",1,'first');
    Y = firstAltSession-0.5;
    
    %Bias and Cue Side
    for j = 1:2
        ax(j) = nexttile();
        img = imagesc(P.(fields(j))); hold on;
        if ~isempty(Y)
            plot([0.5,1.5],[Y,Y],'-r','LineWidth',lineWidth);
        end
        set(ax,'CLim',clims,'XTickLabel',[],'PlotBoxAspectRatio',[1,size(P.(fields(j)),1),1]);
    end
    ax(2).YTickLabel = [];
    
    %Rewarded and unrewarded choices
    for j = 3:4
        ax(j) = nexttile([1,nBack]);

        CData = P.(fields(j)); %Present as Choice(n-1):Choice(n-5)
        X = -(size(CData,2):-1:1);
        img = imagesc(CData); hold on;
        if ~isempty(Y)
            plot([0.5,size(P.(fields(j)),2)+0.5],[Y,Y],'-r','LineWidth',lineWidth);
        end
        set(ax(j),'CLim',clims,'XTick',1:nBack,'XTickLabel',-(1:nBack),'PlotBoxAspectRatio',[1,nBack,1]);
    end
    ax(2).YTickLabel = [];
     
    title(subjects(i).ID,'Interpreter','none');
    set(ax, 'PlotBoxAspectRatio',[1,3,1], 'CLim', clims);
    xlabel('Lag (number of trials)');
    ylabel('Session number');
    xlim([X(1)-0.5,X(numel(idx))+0.5]);
    
    if i == numel(subjects)
        b = colorbar();
        b.Label.String = 'Pearson''s R';
    end
end