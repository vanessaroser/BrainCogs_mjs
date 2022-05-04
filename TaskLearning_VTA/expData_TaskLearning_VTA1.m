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

dirs.data = fullfile(dirs.root,'Data'); 
dirs.notebook = fullfile(dirs.root,'Notebook'); 
dirs.results = fullfile(dirs.root,'Results');
dirs.summary = fullfile(dirs.root,'Summary');
dirs.figures = fullfile(dirs.root,'Figures');

%% First VTA Cohort (N=4)
i=1;
% expData(i) = CombinedImagingBehavior(fullfile(dirs.data,'220404 M411 T7 1Chan_test'));
% expData(i).sub_dir = '220404 M411 T7 1Chan_test';
% expData(i).subjectID = "mjs20_411";
% expData(i).npCorrFactor = 0.5;
% 
% i=i+1;
% expData(i) = CombinedImagingBehavior(fullfile(dirs.data,'220404 M411 T7 1Chan_test'));
expData(i).sub_dir = '220404 M411 T7 1Chan';
expData(i).subjectID = "mjs20_411";
expData(i).mainMaze = 7;
expData(i).npCorrFactor = 0.5;

% i=1;
% expData(i).sub_dir  = '220311 M413 T7'; 
% expData(i).logfile  = 'mjs_taskLearning_VTA_1_Bezos2_mjs20_413_T_20220311.mat';
% expData(i).npCorrFactor = 0.5;

% i = i+1;
