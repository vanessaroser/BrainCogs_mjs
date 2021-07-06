
%Set paths
close all;
experiment = 'mjs_taskLearning_NAc_DREADD2'; %If empty, fetch data from all experiments
dirs = addGitRepo('General','TankMouseVR','U19-pipeline-matlab','BrainCogs_mjs');
dirs.data = fullfile(dirs.root,'Task Learning','data');
dirs.results = fullfile(dirs.root,'Task Learning','results',experiment);
dirs.summary = fullfile(dirs.root,'Task Learning','summary',experiment);
dirs.intake = fullfile(dirs.root,'Task Learning','results');

matfiles = struct(...
    'behavioralData', @(SubjectID) fullfile(dirs.results, [SubjectID,'.mat']),... %Define function later
    'motorTrajectory', fullfile(dirs.summary,'Motor_Trajectory.mat'));

%Hyperparams
dataSource = struct('remoteLogData',true,'experimentData',false,...
    'localLogData',false,'DataJoint',false);
exe = struct(...
    'reloadData',           true,...
    'updateExperData',      true,...
    'motor_trajectory',     false,...
    'dailyIntakeTable',     false,...
    'writeIntake2DB',       false);
plots = struct(...
    'motor_trajectory',             false,...
    'collision_locations',          true,...
    'longitudinal_performance',     false,...
    'group_performance',            false);

%Subject info
if exe.reloadData
    clearvars subjects;
    subjects = struct(...
        'ID',       {"mjs20_11","mjs20_12","mjs20_13","mjs20_14","mjs20_15","mjs20_16","mjs20_17"},...
        'rigNum',   {"rig1",    "rig2",     "rig3",     "rig4",     "rig5", "rig6",     "rig7"},...
        'dreadd',   {false,     false,      true,      true,      false,     true,      false },...
        'startDate', datetime('2021-06-15'),... 
        'experimenter', 'mjs20',... 
        'waterType', 'Milk');
%     subjects = getCNOTests(subjects, experiment); %Append CNO/DREADD details
end

%Switch data source
if dataSource.remoteLogData
    setupDataJoint_mjs();
    subjects = getRemoteVRData( experiment, subjects ); %***Store BAD SESSION flag*** 
elseif dataSource.DataJoint
    setupDataJoint_mjs();
    for i = 1:numel(subjects)
        key = struct('subject_fullname',subjects(i).ID);
        djData = getDBData(key,experiment);
        fields = fieldnames(djData);
        for j=1:numel(fields)
            subjects(i).(fields{j}) = djData.(fields{j});
        end
    end
    
elseif dataSource.experimentData
    subjects = loadExperData({subjects.ID},dirs);    
elseif dataSource.localLogData
end

%Save experimental data to matfiles by subject
if exe.updateExperData % && ~dataSource.experimentData
    fnames = updateExperData(subjects,dirs); 
end

%Append Labels for Session Types
%*** Put these labels in subjects.sessions ***
%   sessions(i).manipulation = CNO dose, etc
%   sessions(i).sessionType = {shaping, sensory, alternation...}
subjects = getSessionLabels(subjects);

%Exclusions
%**M11 & M12 were switched in different rigs on 210702... 
%   M12 (rig 1) might be used, but M11 got a premature Maze 6. Could probably just exclude...
subjects = excludeBadSessions(subjects,experiment);

%Generate table for daily fluid intake and weight
if exe.dailyIntakeTable
    intake = dailyIntakeTable(subjects, dirs);
    if exe.writeIntake2DB
        dirs = getDirs(experiment);
        intakeXLS = fullfile(dirs.intake,'Daily_Intake_All_Subjects.xls');
        tables = {action.Weighing, action.WaterAdministration};
        writeDB_fromXLS(intakeXLS, tables)
    end
end

%Save Stats for View-Angle and X-Trajectories
if exe.motor_trajectory
    create_dirs(dirs.summary);
    trajectories = getTrajectoryDist(subjects);
    save(matfiles.motorTrajectory,'-struct','trajectories');
end

%Plot View-Angle and X-Trajectory for each session
if plots.motor_trajectory
    saveDir = fullfile(dirs.results,'Motor Trajectories');
    create_dirs(saveDir);
    if ~exist('trajectories')
        trajectories = load(matfiles.motorTrajectory);
    end
    params.annotation = true;
    figs = fig_motorTrajectory(trajectories,'fiveNumSummary',params);
    save_multiplePlots(figs, saveDir);
    clearvars figs;
end

%Plot Individual Longitudinal Performance
if plots.longitudinal_performance
    %Full performance data for each subject
%     figs = fig_longitudinal_performance(subjects,'pCorrect');
%  figs = fig_longitudinal_performance(subjects,'pCorrect','mean_pSkid');
%  figs = fig_longitudinal_performance(subjects,'pCorrect','mean_stuckTime');
    figs = fig_longitudinal_performance(subjects,'pCorrect','pStuck');
    saveDir = fullfile(dirs.results,'Performance');
    save_multiplePlots(figs,saveDir);
    clearvars figs;
end

%Plot Group Learning Curve
if plots.group_performance

    saveDir = fullfile(dirs.results,'Group Performance');
    save_multiplePlots(figs,saveDir);
    clearvars figs;
end

if plots.collision_locations
    %Full performance data for each subject
%     figs = fig_longitudinal_performance(subjects,'pCorrect');
%  figs = fig_longitudinal_performance(subjects,'pCorrect','mean_pSkid');
%  figs = fig_longitudinal_performance(subjects,'pCorrect','mean_stuckTime');
    figs = fig_collision_locations(subjects);
    saveDir = fullfile(dirs.results,'Motor Trajectories');
    save_multiplePlots(figs,saveDir);
    clearvars figs;
end
