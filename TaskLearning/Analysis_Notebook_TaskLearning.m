
%Set paths
close all;
experiment = 'mjs_taskLearning_NAc_DREADD2'; %If empty, fetch data from all experiments

dirs = addGitRepo('General','TankMouseVR','U19-pipeline-matlab','BrainCogs_mjs');
dirs.data = fullfile(dirs.root,'Task Learning','data');
dirs.results = fullfile(dirs.root,'Task Learning','results',experiment);
dirs.summary = fullfile(dirs.root,'Task Learning','summary',experiment);
dirs.intake = fullfile(dirs.root,'Task Learning','results');

create_dirs(dirs.results, dirs.summary, dirs.intake);

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
    'model_strategy',       false,...
    'dailyIntakeTable',     false,...
    'writeIntake2DB',       false);
plots = struct(...
    'motor_trajectory',                 false,...
    'collision_locations',              false,...
    'trial_duration',                   false,...
    'longitudinal_performance',         true,...
    'longitudinal_glm_choice_outcome',  true,...
    'glm_cueSide_priorChoice',          false,... %Probably not needed after including glm_choice_outcome
    'glm_choice_outcome',               false,...
    'glm_choice_conflict',              false,...
    'choice_autocorrelation',           true,...
    'group_performance',                true);

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
    subjects = getCNOTests(subjects, experiment); %Append CNO/DREADD details
end

%Switch data source
if dataSource.remoteLogData && ~dataSource.experimentData
    setupDataJoint_mjs();
    subjects = getRemoteVRData( experiment, subjects ); %***Store BAD SESSION flag*** 
elseif dataSource.DataJoint && ~dataSource.experimentData
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

%Append Labels for Session Types
subjects = getSessionLabels(subjects);

%Exclusions
subjects = excludeBadSessions(subjects,experiment);

%Save experimental data to matfiles by subject
if exe.updateExperData && ~dataSource.experimentData
    fnames = updateExperData(subjects,dirs); 
end

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
    trajectories = getTrajectoryDist(subjects);
    save(matfiles.motorTrajectory,'-struct','trajectories');
end

if exe.model_strategy
    subjects = analyzeTaskStrategy(subjects);
end

%Get Colors for Plotting
cbrew = brewColorSwatches;
colors = setPlotColors(cbrew,experiment);

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

if plots.collision_locations
    figs = fig_collision_locations(subjects);
    saveDir = fullfile(dirs.results,'Motor Trajectories');
    save_multiplePlots(figs,saveDir);
    clearvars figs;
end

if plots.trial_duration
    saveDir = fullfile(dirs.results,'Trial Duration');
    figs = fig_longitudinal_trialDuration( subjects );
    save_multiplePlots(figs,saveDir);
    clearvars figs;
end


%Plot Individual Longitudinal Performance
if plots.longitudinal_performance
    %Full performance data for each subject
    saveDir = fullfile(dirs.results,'Performance');
    vars = {["pCorrect_congruent","pCorrect_conflict"],"mean_pSkid","mean_velocity"};
    for i = 1:numel(vars)
        figs = fig_longitudinal_performance(subjects,vars{i},colors);
        save_multiplePlots(figs,saveDir);
        clearvars figs;
    end
    
end

if plots.glm_cueSide_priorChoice
    saveDir = fullfile(dirs.results,'GLM');
    vars = {...
        {'cueSide','priorChoice','bias'},...
        {'R_cue_choice', 'R_priorChoice_choice', 'R_predictors'},...
        {'pRightChoice', 'pRightCue'},...
        };    
    for i = 1:numel(vars)
        figs = fig_longitudinal_glm(subjects,vars{i});
        save_multiplePlots(figs,saveDir);
        clearvars figs;
    end  
end

if plots.glm_choice_outcome
    %For each session
    saveDir = fullfile(dirs.results,'GLM_Choice_Outcome');
    figs = fig_glm_choice_outcome(subjects,'glm3');
    save_multiplePlots(figs,saveDir);
    clearvars figs;
end

if plots.longitudinal_glm_choice_outcome
    %Longitudinal
    saveDir = fullfile(dirs.results,'GLM_Choice_Outcome');
    vars = {'cueSide','rewChoice','unrewChoice','bias'};   
    figs{1} = fig_longitudinal_glm_choice_outcome( subjects, vars );
    figs{2} = fig_choice_autocorrelation(subjects);
    save_multiplePlots([figs{:}],saveDir);
    clearvars figs;
%Check for warning messages
%W = arrayfun(@(idx) isfield(S(idx).glm3,'warning'), 1:numel(S));
end

if plots.glm_choice_conflict
    saveDir = fullfile(dirs.results,'GLM_Choice_Conflict');
    vars = {{'congruent','conflict','bias'}};   
%     vars = {...
%         {'Congruent','Conflict','bias'},...
%         {'pRightChoice', 'pConflict', 'pReward'},...
%         {'R_predictors','R_conflict_choice', 'R_congruent_choice'},...
%         {'N', 'conditionNum'},...
%         };   
    
    for i = 1:numel(vars)
        figs = fig_glm_choice_conflict(subjects,vars{i});
        save_multiplePlots(figs,saveDir);
        clearvars figs;
    end    
end

%Plot Group Learning Curve
if plots.group_performance
    saveDir = fullfile(dirs.results,'Group Performance');
    vars = ["pCorrect","pCorrect_conflict","pOmit","nCompleted","mean_velocity"];
    for i = 1:numel(vars)
        figs(i,:) = fig_periswitch_alternation(subjects, vars(i));
    end
    save_multiplePlots(figs,saveDir);
    clearvars figs;
end

if plots.cno_sessions
    %Group performance following introduction of memory region
    vars = ["pCorrect","pOmit","nCompleted","mean_velocity"];
    for i = 1:numel(vars)
        nPreTestSessions = 5;
        figs(i,:) = fig_cnoSessions_alternation(subjects, vars(i), nPreTestSessions);
    end
    save_multiplePlots(figs,dirs.results); 
end


