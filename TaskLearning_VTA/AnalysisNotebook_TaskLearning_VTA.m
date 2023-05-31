%Set paths
close all;
experiment = 'mjs_taskLearning_VTA_1'; %If empty, fetch data from all experiments
dirs = getRoots();
addGitRepo(dirs,'General','TankMouseVR','U19-pipeline-matlab','BrainCogs_mjs');
dirs.data = fullfile(dirs.root,'TaskLearning_VTA','data');
dirs.results = fullfile(dirs.root,'TaskLearning_VTA','results',experiment);
dirs.summary = fullfile(dirs.root,'TaskLearning_VTA','summary',experiment);
dirs.intake = fullfile(dirs.root,'TaskLearning_VTA','results');

create_dirs(dirs.results, dirs.summary, dirs.intake);

matfiles = struct(...
    'behavioralData', @(SubjectID) fullfile(dirs.results, [SubjectID,'.mat']),... %Define function later
    'motorTrajectory', fullfile(dirs.summary,'Motor_Trajectory.mat'));

%Hyperparams
dataSource = struct('remoteLogData',true,'experimentData',true,...
    'localLogData',false,'DataJoint',false);
exe = struct(...
    'reloadData',           false,...
    'updateExperData',      true,...
    'motor_trajectory',     false,...
    'model_strategy',       false);
plots = struct(...
    'motor_trajectory',                 false,...
    'collision_locations',              false,...
    'trial_duration',                   false,...
    'longitudinal_performance',         false,...
    'longitudinal_glm_choice_outcome',  false,...
    'glm_cueSide_priorChoice',          false,... %Probably not needed after including glm_choice_outcome
    'glm_choice_outcome',               false,...
    'group_performance',                true);

%Subject info
if exe.reloadData
    clearvars subjects;
    subjects = struct(...
        'ID',       {"mjs20_410","mjs20_411","mjs20_412","mjs20_413"},...
        'rigNum',   {"Bezos2", "Bezos2", "Bezos2", "Bezos2"},...
        'startDate', datetime('2022-01-10'),...
        'experimenter', 'mjs20',...
        'waterType', 'Milk');
    
    
    %Switch data source
    if dataSource.remoteLogData && ~dataSource.experimentData
        setupDataJoint_mjs();
        subjects = getRemoteVRData( experiment, subjects ); 
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

%Append Labels for Session Types
subjects = getSessionLabels_TaskLearning_VTA(subjects);
%Exclude warmup trials from correct rate for Sensory and Alternation Mazes
subjects = filterSessionStats(subjects, 5);

%Save experimental data to matfiles by subject
if exe.updateExperData % && ~dataSource.experimentData
    fnames = updateExperData(subjects,dirs);
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
        {'pCorrect','bias'},...
        {'maxCorrectMoving_congruent','maxCorrectMoving_conflict'},...
        {'median_velocity','pOmit'},{'pStuck','median_pSkid'}};
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


%Plot Group Learning Curve
if plots.group_performance
    saveDir = fullfile(dirs.results,'Group Performance');
%     figs = fig_periswitch_sensory(subjects, 'pCorrect');
%     save_multiplePlots(figs,saveDir);
%     clearvars figs;
    vars = ["pCorrect","pCorrect_conflict","maxCorrectMoving_conflict"];
    params = struct('nSensory',4,'nAlternation','min','colors',colors);
    for i = 1:numel(vars)
    figs(i) = fig_periswitch_alternation(subjects,vars(i),params);
    end
    save_multiplePlots(figs,saveDir);
    clearvars figs;
end

% ------------- NOTES ------
% 220107 Started all subjects informally on Level 1 on (M412 & M413 w/ imaging)
% 220110 Begin formal training
% 220112 Imaged M412 to determine whether sufficient clearance was allowed for objective/FOV.
% 220113 Switched from 2 1.5mm washers to 1 2mm washer. Headplate-to-ball elevation, approx. 27 mm.
% 220317 Accidentally started M413 on T6 before resuming on T7...
% 220318 Same thing...
