clearvars;

experiment = ["mjs_memoryMaze_NAc_DREADD_performance"]; %If empty, fetch data from all experiments
subject = struct(...
    'ID',    {'mjs20_439','mjs20_665','mjs20_441','mjs20_443','mjs20_447','mjs20_449','mjs20_658'},...
    'rigNum',{'rig1',     'rig2',     'rig3',     'rig4',     'rig5',     'rig6',     'rig7'},...
    'startDate',datetime('2021-02-08'));

dirs.data = fullfile('C:','Data','MemoryMaze','data');
dirs.save = fullfile('C:','Data','MemoryMaze','results',experiment);
dirs.results = fullfile('C:','Data','MemoryMaze','results');


% fnames = saveExperData(dirs, experiment, subject);