function figs = histogram_summaryPreference(selectivity_struct, field, figName, params)
S = selectivity_struct;
sessions = unique(S.session);
C = cbrewer('qual','Set1',9);

if field=="meanPreference"
    colors = {C(8,:),C(2,:)}; %pink, blue
else
    colors = {C(2,:),C(1,:)}; %blue, red
end

%Histogram by session
for i = 1:numel(sessions)
    figs(i) = figure('Name',join([figName "-" sessions(i)],''),'Position',[100,100,1400,400]);
    cellIdx = S.session==sessions(i);
    makeHistogram(S, field, cellIdx, params, colors);
end

%Histogram by subject/rule
subjects = unique(S.subject);
for i = 1:numel(subjects)
    figs(numel(figs)+1) = figure('Name',join([figName "-" subjects(i)],''),'Position',[100,100,1400,400]);
    cellIdx = S.subject==subjects(i);
    makeHistogram(S, field, cellIdx, params, colors)
end

%Histogram by rule (all sessions)
figs(numel(figs)+1) = figure('Name',figName,'Position',[100,100,1400,400]);
makeHistogram(S, field, 1:numel(S.session), params, colors)

%Histogram by rule (selected last sessions)
figs(numel(figs)+1) = figure('Name',join([figName "-lastSessions"],''),'Position',[100,100,1400,400]);
cellIdx = ismember(S.session, ["220323 M411 T6 pseudorandom","220309 M413 T6 pseudorandom",... %sensory
    "220613 M411 T7","220615 M411 T7","220701 M413 T7"]); %alternation
makeHistogram(S, field, cellIdx, params, colors);

function makeHistogram(S, field, cellIdx, params, colors)
for j = 1:numel(params)
    
    h = subplot(1,4,j);
    data = S.(params(j).comparison).(field)(cellIdx); 

    %Comparison statistic & corresponding edges
    stat = 'preference';
    edges = params(j).edges;
    if field=="meanSelectivity"
        stat = 'selectivity';
        edges = unique(abs(edges));
    end

    %Compute histogram and plot
    N = histcounts(data, edges);
    Median = median(data);
    histogram(data, edges, 'DisplayStyle', 'bar', 'LineWidth', 1, 'FaceColor', colors{1}); hold on;
    plot(Median.*[1,1],[0,max(N)+0.05*max(N)], 'LineWidth', 1, 'Color', colors{2});
    
    title(params(j).title);
    xlabel(params(j).dataLabel.(stat));
    ylabel('Number of neurons')
    axis square;

end