%Set paths
close all;
experiment = 'mjs_taskLearningWalls'; %If empty, fetch data from all experiments

dirs = addGitRepo('General','TankMouseVR','U19-pipeline-matlab','BrainCogs_mjs');
dirs.data = fullfile(dirs.root,'TaskLearning_VTA','data');
dirs.results = fullfile(dirs.root,'TaskLearning_VTA','results',experiment);
dirs.summary = fullfile(dirs.root,'TaskLearning_VTA','summary',experiment);
dirs.intake = fullfile(dirs.root,'TaskLearning_VTA','results');

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
    'motor_trajectory',     true,...
    'model_strategy',       true,...
    'dailyIntakeTable',     false,...
    'writeIntake2DB',       false);
plots = struct(...
    'motor_trajectory',                 true,...
    'collision_locations',              true,...
    'trial_duration',                   true,...
    'longitudinal_performance',         true,...
    'longitudinal_glm_choice_outcome',  true,...
    'glm_cueSide_priorChoice',          false,... %Probably not needed after including glm_choice_outcome
    'glm_choice_outcome',               false,...
    'glm_choice_conflict',              false,...
    'group_performance',                true);

%Subject info
if exe.reloadData
    clearvars subjects;
    subjects = struct(...
        'ID',       {"mjs20_09","mjs20_10","mjs20_18","mjs20_19","mjs20_20"},...
        'rigNum',   {"rig1_188", "rig2_188", "rig1_188", "rig2_188", "rig1_188"},...
        'startDate', datetime('2021-08-19'),...
        'experimenter', 'mjs20',...
        'waterType', 'Milk');
    
    
    %Switch data source
    if dataSource.remoteLogData && ~dataSource.experimentData
        setupDataJoint_mjs();
        subjects = getRemoteVRData( experiment, subjects ); %***Store BAD SESSION flag***
    elseif dataSource.DataJoint && ~dataSource.experimentData
        setupDataJoint_mjs();
        for i = 1:numel(subjects)
            key = struct('subject_fullname',char(subjects(i).ID));
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
end

%Exclusions (should be combined with the block exclusions in getVRData())
% subjects = excludeBadSessions(subjects,experiment);

%Append Labels for Session Types
subjects = getSessionLabels_LMaze(subjects);

%Save experimental data to matfiles by subject
if exe.updateExperData % && ~dataSource.experimentData
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
    if ~exist('trajectories','var')
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
    figs = fig_longitudinal_trialDuration( subjects,experiment );
    save_multiplePlots(figs,saveDir);
    clearvars figs;
end


%Plot Individual Longitudinal Performance
if plots.longitudinal_performance
    %Full performance data for each subject
    saveDir = fullfile(dirs.results,'Performance');
    vars = {{'pCorrect_congruent','pCorrect_conflict'},...
        {'maxCorrectMoving_congruent','maxCorrectMoving_conflict'},...
        {'mean_velocity','pOmit'},{'pStuck','mean_pSkid'}};
    for i = 1:numel(vars)
        figs = fig_longitudinal_performance(subjects,vars{i},colors);
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
    figs{1} = fig_longitudinal_glm_choice_outcome( subjects, vars, colors );
    figs{2} = fig_choice_autocorrelation(subjects);
    save_multiplePlots([figs{:}],saveDir);
    clearvars figs;
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
    figs = fig_periswitch_sensory(subjects, 'pCorrect');
    save_multiplePlots(figs,saveDir);
    clearvars figs;
    vars = ["pCorrect","pCorrect_conflict","maxCorrectMoving_conflict"];
    params = struct('nSensory',4,'nAlternation','min','colors',colors);
    for i = 1:numel(vars)
    figs(i) = fig_periswitch_alternation(subjects,vars(i),params);
    end
    save_multiplePlots(figs,saveDir);
    clearvars figs;
end

% ------------- NOTES ------
%211020 Dropped pressure to slow ball rotation
%211029 Introduced back dampers to slow ball rotation
%211111 Introduced side dampers
%211108 Introduced Air Puffs for Negative Outcome
%211119 Reduced Cue Density from 5/cm to 3/cm
%211123 Shortened main stem length from 200 to 150 cm
%211126 Shortened main stem length to 100 cm for mjs09 and mjs10, later mjs18 and mjs19
%211213 Shortened main stem length to 100 cm for mjs20