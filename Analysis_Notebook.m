clearvars;

%Hyperparams
exe = struct('dailyIntakeTable',false,'updateExperData',false); 

experiment = "mjs_memoryMaze_NAc_DREADD_performance"; %If empty, fetch data from all experiments

subject = struct(...
    'ID',    {'mjs20_439','mjs20_665','mjs20_441','mjs20_443','mjs20_447','mjs20_449','mjs20_658'},...
    'rigNum',{'rig1',     'rig2',     'rig3',     'rig4',     'rig5',     'rig6',     'rig7'},...
    'startDate',datetime('2021-02-08'));

getDirs = @(experiment) struct(...
    'data',fullfile('C:','Data','MemoryMaze','data'),...
    'save',fullfile('C:','Data','MemoryMaze','results',experiment),...
    'results',fullfile('C:','Data','MemoryMaze','results'));

%Generate table for daily fluid intake and weight
if exe.dailyIntakeTable
    dataStruct = dailyIntakeTable(getDirs([]), [], subject);
end

%Save experimental data to matfiles by subject
if exe.updateExperData
    fnames = updateExperData(getDirs(experiment), experiment, subject);
end
