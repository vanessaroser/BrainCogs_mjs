function figs = histogram_summaryPreference(selectivity_struct, field, figName, figType, params)
S = selectivity_struct;
sessions = unique(S.session);
C = cbrewer('qual','Set1',9);

if field=="meanPreference"
    colors = {C(8,:),C(2,:)}; %pink, blue
else
    colors = {C(2,:),C(1,:)}; %blue, red
end
figs = gobjects(0); %initialize

for i = 1:numel(figType)
    switch figType(i)
        case "session"
            %Histogram by session
            for j = 1:numel(sessions)
                figs(j) = figure('Name',join([figName "-" sessions(j)],''),'Position',[100,100,1500,300]);
                cellIdx = S.session==sessions(j);
                makeHistogram(S, field, cellIdx, params, colors);
            end
        case "subject"
            %Histogram by subject/rule
            subjects = unique(S.subject);
            for j = 1:numel(subjects)
                figs(numel(figs)+1) = figure('Name',join([figName "-" subjects(j)],''),'Position',[100,100,1500,300]);
                cellIdx = S.subject==subjects(j);
                makeHistogram(S, field, cellIdx, params, colors)
            end
        case "all"
            %Histogram by rule (all sessions)
            figs(numel(figs)+1) = figure('Name',figName,'Position',[100,100,1500,300]);
            makeHistogram(S, field, 1:numel(S.session), params, colors)
        case "last"
            %Histogram by rule (selected last sessions)
            figs(numel(figs)+1) = figure('Name',join([figName "-lastSessions"],''),'Position',[100,100,1500,300]);
            cellIdx = ismember(S.session, ["220323 M411 T6 pseudorandom","220309 M413 T6 pseudorandom",... %sensory
                "220613 M411 T7","220615 M411 T7","220701 M413 T7"]); %alternation
            makeHistogram(S, field, cellIdx, params, colors);
    end
end

function makeHistogram(S, field, cellIdx, params, colors)
for i = 1:numel(params)

    h = subplot(1,numel(params),i);
    data = S.(params(i).comparison).(field)(cellIdx);

    %Comparison statistic & corresponding edges
    stat = 'preference';
    edges = params(i).edges;
    if field=="meanSelectivity"
        stat = 'selectivity';
        edges = unique(abs(edges));
    end

    %Compute histogram and plot
    N = histcounts(data, edges);
    Median = median(data);
    histogram(data, edges, 'DisplayStyle', 'bar', 'LineWidth', 1, 'FaceColor', colors{1}); hold on;
    plot(Median.*[1,1],[0,max(N)+0.05*max(N)], 'LineWidth', 1, 'Color', colors{2});

    title(params(i).title);
    xlabel(params(i).dataLabel.(stat));
    ylabel('Number of neurons')
    axis square;

end