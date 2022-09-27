%%% pathList_TaskLearning_VTA1
%
%PURPOSE:   Set up paths to run all analyses of longitudinal imaging &
%               behavior during learning.
%AUTHORS: MJ Siniscalchi, 220404
%
%--------------------------------------------------------------------------
function dirs = pathList_bezosCup_VTA1

% Get name of computer to specify paths
switch getenv('COMPUTERNAME')
    case 'PNI-F4W2YM2' %KwanLab desktop, 'STELLATE'
        dirs.root = 'Y:\Michael\_prelim analysis';
        dirs.code = 'C:\Users\mjs20\Documents\GitHub\';
    case 'WINDOWS-CVO3377' %HP Laptop
end

% add the paths needed for this code
path_list = {...
    dirs.code;...
    fullfile(dirs.code,'BrainCogs_mjs');...
    fullfile(dirs.code,'BrainCogs_mjs','TaskLearning_VTA');...
    fullfile(dirs.code,'BrainCogs_mjs','TaskLearning_VTA','cell fluo');...
    fullfile(dirs.code,'BrainCogs_mjs','TaskLearning_VTA','figures');...
    fullfile(dirs.code,'BrainCogs_mjs','TaskLearning_VTA','common functions');...
    fullfile(dirs.code,'BrainCogs_mjs','TaskLearning_VTA','common functions','cbrewer');...
    };
addpath(path_list{:});