
%Set paths
close all;
experiment = 'mjs_memoryMaze_NAc_DREADD_performance'; %If empty, fetch data from all experiments

dirs = addGitRepo('General','TankMouseVR','U19-pipeline-matlab','BrainCogs_mjs','MemoryMaze');
dirs.data = fullfile(dirs.root,'MemoryMaze','data');
dirs.results = fullfile(dirs.root,'MemoryMaze','results',experiment);
dirs.summary = fullfile(dirs.root,'MemoryMaze','summary',experiment);
dirs.intake = fullfile(dirs.root,'MemoryMaze','results');

matfiles = struct(...
        'motorTrajectory', fullfile(dirs.summary,'Motor_Trajectory.mat'));

%Hyperparams
dataSource = struct('remoteLogData',false,'experimentData',true,...
    'localLogData',false,'DataJoint',false);
exe = struct(...
    'reloadData',       true,...
    'updateExperData',  false,...
    'motorTrajectory',  true,...
    'dailyIntakeTable', false,...
    'writeIntake2DB',   false);
plots = struct(...
    'longitudinal_performance', false,...
    'motorTrajectory',          true,...
    'switch_conditions',        false,...
    'cno_sessions',             false...
    );

%Subject info
if exe.reloadData
    clearvars subjects;
    subjects = struct(...
        'ID',       {"mjs20_439","mjs20_665","mjs20_441","mjs20_443","mjs20_447","mjs20_449","mjs20_658"},...
        'rigNum',   {"rig1","rig2","rig3","rig4","rig5","rig6","rig7"},...
        'dreadd',   {false,      true,       false,      true,       false,      true,       false },...
        'startDate', datetime('2021-02-08'),... 
        'experimenter', 'mjs20',... 
        'waterType', 'Milk');
    subjects = getCNOTests(subjects); %Append CNO/DREADD details
end

%Switch data source
if dataSource.remoteLogData
    setupDataJoint_mjs();
    subjects = getRemoteVRData( experiment, subjects ); %***Store BAD SESSION flag*** 
elseif dataSource.DataJoint
    setupDataJoint_mjs();
    %     data = getDBData(subjects); %Enclose getDBPerformanceData() and the water/weight fetches here...
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

%Exclusions
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

%Save stats for x-position and view angle
if exe.motorTrajectory
    create_dirs(dirs.summary);
    trajectories = getTrajectoryDist(subjects);
    save(matfiles.motorTrajectory,'-struct','trajectories');
end

%Plot Longitudinal Performance
if plots.motorTrajectory
%     saveDir = fullfile(dirs.results,'Motor Trajectories');
    saveDir = fullfile(dirs.results,'Motor Trajectories (alt)');
    create_dirs(saveDir);
    if ~exist('trajectories')
%         trajectories = load(matfiles.motorTrajectory);
        trajectories = getTrajectoryDist_alt(subjects);
    end
    params.annotation = true;
%     figs = fig_motorTrajectory(trajectories,'fiveNumSummary',params);
%     figs = fig_motorTrajectory_alt(trajectories,'fiveNumSummary',params);
    save_multiplePlots(figs, saveDir);
    clearvars figs;
end

%Plot Longitudinal Performance
if plots.longitudinal_performance
    %Full performance data for each subject
    figs = fig_longitudinal_performance(subjects,'pCorrect');
%      figs(i,:) = fig_periswitch_mem(subjects, vars(i));
%         figs(i,:) = fig_sensory2memory(subjects, vars(i));
    save_multiplePlots(figs,dirs.results);
    clearvars figs;
end

if plots.switch_conditions
    %Performance around task changes
    vars = ["pCorrect","pOmit","nCompleted","mean_velocity"];
    for i = 1:numel(vars)
        figs(i,:) = fig_periswitch_mem(subjects, vars(i));
    end
%     for i = 1:numel(vars)
%         figs(size(figs,1)+1,:) = fig_sensory2memory(subjects, vars(i));
%     end
    save_multiplePlots(figs,dirs.results);
    clearvars figs;
end

if plots.cno_sessions
    %Group performance following introduction of memory region
    %     vars = {'pCorrect','pOmit','nCompleted','mean_velocity'};
    vars = ["pCorrect","pOmit","nCompleted","mean_velocity"];
    for i = 1:numel(vars)
        nPreTestSessions = 5;
        figs(i,:) = fig_cnoSessions(subjects, vars(i), nPreTestSessions);
    end
    save_multiplePlots(figs,dirs.results); 
end

%Save working copy of data (Data probably too large for this...)
% if exe.saveResults
%     if ~isfield(dirs,'results')
%         dirs = getDirs(experiment);
%     end
%     save(fullfile(dirs.results,'saved_data.mat'),'-struct','data');
% end