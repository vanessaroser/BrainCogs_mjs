clearvars;

matfiles.cohort1 =... 
    {'C:\Data\Task Learning\results\mjs_taskLearning_NAc_DREADD2\mjs20_11.mat';...
    'C:\Data\Task Learning\results\mjs_taskLearning_NAc_DREADD2\mjs20_12.mat';...
    'C:\Data\Task Learning\results\mjs_taskLearning_NAc_DREADD2\mjs20_13.mat';...
    'C:\Data\Task Learning\results\mjs_taskLearning_NAc_DREADD2\mjs20_14.mat';...
    'C:\Data\Task Learning\results\mjs_taskLearning_NAc_DREADD2\mjs20_15.mat';...
    'C:\Data\Task Learning\results\mjs_taskLearning_NAc_DREADD2\mjs20_16.mat';...
    'C:\Data\Task Learning\results\mjs_taskLearning_NAc_DREADD2\mjs20_17.mat'};
matfiles.cohort2 =... 
    {'C:\Data\LMaze\results\mjs_taskLearningWalls\mjs20_09.mat';...
    'C:\Data\LMaze\results\mjs_taskLearningWalls\mjs20_10.mat';...
    'C:\Data\LMaze\results\mjs_taskLearningWalls\mjs20_18.mat';...
    'C:\Data\LMaze\results\mjs_taskLearningWalls\mjs20_19.mat';...
    'C:\Data\LMaze\results\mjs_taskLearningWalls\mjs20_20.mat'};

for i = 1:numel(matfiles.cohort1)
    cohort1(i) = load(matfiles.cohort1{i},'ID','sessions');
end
for i = 1:numel(matfiles.cohort2)
    cohort2(i) = load(matfiles.cohort2{i},'ID','sessions');
end

%Crunch performance data
for i = 1:numel(cohort1)
    level = cellfun(@min,{cohort1(i).sessions.level});
    perf = [cohort1(i).sessions.pCorrect];
    nSensory.coh1(i) = find(level<7 & level>4 & perf>0.8 & perf<0.9,1,'last');
end

for i = 1:numel(cohort2)
    level = cellfun(@min,{cohort2(i).sessions.level});
    nForced(i) =  find(level<7,1,'last');
    nSensory.coh2(i) = find(level<9,1,'last') - nForced(i);
end

%Scatter to relate nForced to nSensory
figs(1) = figure('Name','Scatter_LMaze_Comparison');
cbrew = brewColorSwatches;
colors = {cbrew.blue; cbrew.black; cbrew.gray; cbrew.blue};
transparency = [0.4,0,0.4,0.4];
boxWidth = 0.5;
lineWidth = 2;

scatter(nForced,nSensory.coh2,'LineWidth',lineWidth,'MarkerFaceColor',cbrew.blue)
axis square
ylabel('Number of Sensory Sessions');
xlabel('Number of L-Maze Sessions')
xlim([10,25]);
ylim([0,10]);

%Box plot of nSessions for each maze condition
figs(2) = figure('Name','nSessions_LMaze_Comparison');
ax=axes;
data = {nSensory.coh1, nSensory.coh2+nForced, nForced, nSensory.coh2};


X = 1:numel(data);
for i=1:numel(data)
    p(i) = plot_basicBox( X(i), data{i}, boxWidth, lineWidth,...
        colors{i}, transparency(i) );
    plot(X(i), data{i},'o','MarkerSize',5,...
        'LineStyle','none','LineWidth',lineWidth,'Color',colors{i}); %Overlay data points
end
%Labels and titles
ylabel('Number of Sessions');
set(ax,'XTickLabel',({'Sensory','All','L-Maze','Sensory'}));
axis square;
xlim([0.5,4.5]);
   
saveDir = 'C:\Data\LMaze\results\mjs_taskLearningWalls\';
save_multiplePlots(figs,saveDir);