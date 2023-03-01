function figs = histogram_summarySelectivity(selectivity_struct, figName, params)
S = selectivity_struct;
sessions = unique(S.session);

%Histogram by session
for i = 1:numel(sessions)
    figs(i) = figure('Name',join([figName "-" sessions(i)],''),'Position',[100,100,1400,400]);
    %tiledlayout(1,numel(params));
    cellIdx = S.session==sessions(i);
    for j = 1:numel(params)
        %nexttile;
        h = subplot(1,4,j);
        data = S.(params(j).comparison).meanSelectivity(cellIdx);
        Median = median(data);
        N = histcounts(data,params(j).edges);
        histogram(data,params(j).edges,'DisplayStyle','bar','LineWidth',1); hold on;
        plot(Median.*[1,1],[0,max(N)+0.1],'r','LineWidth',1)
        title(params(j).title);
        xlabel(params(j).cLabel);
        ylabel('Number of neurons')
        axis square;
    end
end

%Histogram by subject/rule
subjects = unique(S.subject);
for i = 1:numel(subjects)
    figs(numel(figs)+1) = figure('Name',join([figName "-" subjects(i)],''),'Position',[100,100,1400,400]);
    %tiledlayout(1,numel(params));
    cellIdx = S.subject==subjects(i);
    for j = 1:numel(params)
        %nexttile;
        h = subplot(1,4,j);
        data = S.(params(j).comparison).meanSelectivity(cellIdx);
        Median = median(data);
        N = histcounts(data,params(j).edges);
        histogram(data,params(j).edges,'DisplayStyle','bar','LineWidth',1); hold on;
        plot(Median.*[1,1],[0,max(N)+0.1],'r','LineWidth',1)
        title(params(j).title);
        xlabel(params(j).cLabel);
        ylabel('Number of neurons')
        axis square;
    end
end

%Histogram by rule (all sessions)
figs(numel(figs)+1) = figure('Name',figName,'Position',[100,100,1400,400]);
for j = 1:numel(params)
    %nexttile;
    h = subplot(1,4,j);
    data = S.(params(j).comparison).meanSelectivity;
    Median = median(data);
    N = histcounts(data,params(j).edges);
    histogram(data,params(j).edges,'DisplayStyle','bar','LineWidth',1); hold on;
    plot(Median.*[1,1],[0,max(N)+0.1],'r','LineWidth',1)
    title(params(j).title);
    xlabel(params(j).cLabel);
    ylabel('Number of neurons')
    axis square;
end

%Histogram by rule (selected last sessions)
figs(numel(figs)+1) = figure('Name',join([figName "-lastSessions"],''),'Position',[100,100,1400,400]);
for j = 1:numel(params)
    cellIdx = ismember(S.session, ["220323 M411 T6 pseudorandom","220309 M413 T6 pseudorandom",... %sensory
        "220613 M411 T7","220615 M411 T7","220701 M413 T7"]); %alternation
    h = subplot(1,4,j);
    data = S.(params(j).comparison).meanSelectivity(cellIdx);
    Median = median(data);
    N = histcounts(data,params(j).edges);
    histogram(data,params(j).edges,'DisplayStyle','bar','LineWidth',1); hold on;
    plot(Median.*[1,1],[0,max(N)+0.1],'r','LineWidth',1)
    title(params(j).title);
    xlabel(params(j).cLabel);
    ylabel('Number of neurons')
    axis square;
end
