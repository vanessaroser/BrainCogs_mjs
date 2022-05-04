%%% pathList_TaskLearning_VTA1
%
%PURPOSE:   Set up paths to run all analyses of longitudinal imaging &
%               behavior during learning of sensorimotor associations.
%AUTHORS: MJ Siniscalchi & AC Kwan, 190701
%
%--------------------------------------------------------------------------
function data_dir = pathList_TaskLearning_VTA1

% Get name of computer to specify paths
switch getenv('COMPUTERNAME')
    case 'PNI-F4W2YM2' %KwanLab desktop, 'STELLATE'
        data_dir = 'C:\Data\TaskLearning_VTA';
        code_dir = 'J:\Documents\MATLAB\GitHub';
    case 'WINDOWS-CVO3377' %HP Laptop
end

% add the paths needed for this code
path_list = {...
    code_dir;...
    fullfile(code_dir,'BrainCogs_mjs');...
    fullfile(code_dir,'BrainCogs_mjs','TaskLearning_VTA');...
    fullfile(code_dir,'BrainCogs_mjs','TaskLearning_VTA','cell fluo');...
    };
addpath(path_list{:});