function [ dirs, expData ] = expData_TaskLearning_VTA1(dirs)

%PURPOSE: Create data structure for imaging tiff files and behavioral log files
%AUTHORS: AC Kwan, 170519.
%
%INPUT ARGUMENTS
%   data_dir:    The base directory to which the raw data are stored.  
%
%OUTPUT VARIABLES
%   dirs:        The subfolder structure within data_dir to work with
%   expData:     Info regarding each experiment

dirs.data = fullfile(dirs.root,'TaskLearning_VTA','Data'); 
dirs.notebook = fullfile(dirs.root,'TaskLearning_VTA','Notebook'); 
dirs.results = fullfile(dirs.root,'TaskLearning_VTA','Results');
dirs.summary = fullfile(dirs.root,'TaskLearning_VTA','Summary');
dirs.figures = fullfile(dirs.root,'TaskLearning_VTA','Figures');

%% First VTA Cohort (N=4)

% Initialize structure
expData = struct('sub_dir',[],'subjectID',[],'mainMaze',[],...
    'excludeBlock',[],'npCorrFactor',[]);

% Session metadata
i=1;

% expData(i).sub_dir = '220309 M413 T6_test';
% expData(i).subjectID = "mjs20_413";
% expData(i).mainMaze = 6;
% expData(i).npCorrFactor = 0.3;
% i = i+1;
expData(i).sub_dir = '220309 M413 T6 pseudorandom';
expData(i).subjectID = "mjs20_413";
expData(i).mainMaze = 6;
expData(i).npCorrFactor = 0.3;
% i = i+1;
% 
% expData(i).sub_dir = '220615 M413 T7';
% expData(i).subjectID = "mjs20_413";
% expData(i).mainMaze = 7;
% expData(i).npCorrFactor = 0.3;
% i = i+1;
% 
% expData(i).sub_dir = '220701 M413 T7';
% expData(i).subjectID = "mjs20_413";
% expData(i).mainMaze = 7;
% expData(i).npCorrFactor = 0.3;
% i = i+1;
% 
% expData(i).sub_dir = '220323 M411 T6 pseudorandom';
% expData(i).subjectID = "mjs20_411";
% expData(i).mainMaze = 6;
% expData(i).excludeBlock = [1:4]; %Multiple restarts
% expData(i).npCorrFactor = 0.3;
% i = i+1;
% expData(i).sub_dir = '220404 M411 T7 1Chan';
% expData(i).subjectID = "mjs20_411";
% expData(i).mainMaze = 7;
% expData(i).npCorrFactor = 0.3;
% i = i+1;
% expData(i).sub_dir = '220613 M411 T7';
% expData(i).subjectID = "mjs20_411";
% expData(i).mainMaze = 7;
% expData(i).excludeBlock = [1];
% expData(i).npCorrFactor = 0.3;
% i = i+1;
% expData(i).sub_dir = '220629 M411 T8';
% expData(i).subjectID = "mjs20_411";
% expData(i).mainMaze = 8;
% expData(i).npCorrFactor = 0.3;
% 
% expData(i).sub_dir = '220328 M412 T6 pseudorandom';
% expData(i).subjectID = "mjs20_412";
% expData(i).mainMaze = 6;
% expData(i).npCorrFactor = 0.3;
% i = i+1;
% 


