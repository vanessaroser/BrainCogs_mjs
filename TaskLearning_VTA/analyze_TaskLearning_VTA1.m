%---------------------------------------------------------------------------------------------------
% analyze_TaskLearning_VTA1
%
% PURPOSE: To analyze simultaneous imaging and virtual maze running behavior.
%
% AUTHOR: MJ Siniscalchi, Princeton Neuroscience Institute, 220404
%           -based on previous work in Kwan Lab at Yale
%
% NOTES:
%           * If neuropil (background) masks are not generated after cell selection in cellROI.m,
%               use the script get_neuropilMasks_script to generate them post-hoc
%               (much faster than doing it through the GUI...).
%
%---------------------------------------------------------------------------------------------------

% *** Revision Notes ***
% - Block Exclusions should flow to trials.exclude-- so that I2C Data remain consistent.

clearvars;
close all;
experiment = 'mjs_taskLearning_VTA_1'; %If empty, fetch data from all experiments

% Set MATLAB path and get experiment-specific parameters
addGitRepo('General','TankMouseVR','U19-pipeline-matlab','BrainCogs_mjs','scim');
setupDataJoint_mjs();
[dirs, expData] = expData_TaskLearning_VTA1(pathList_TaskLearning_VTA1);

% Set parameters for analysis
[calculate, summarize, figures, mat_file, params] = params_TaskLearning_VTA1(dirs,expData);
expData = get_imgPaths(dirs, expData, calculate, figures); %Append additional paths for imaging data if required by 'calculate'

% Generate directory structure
create_dirs(dirs.results,dirs.summary,dirs.figures);

% Begin logging processes
diary(fullfile(dirs.results,['procLog' datestr(datetime,'yymmdd')]));
diary on;
disp(datetime);

%% CHECK DATA CONSISTENCY AND INITIALIZE FILE FOR COMBINED IMAGING-BEHAVIOR DATA
if calculate.combined_data
    for i = 1:numel(expData)
        %Run basic behavioral processing for each imaging session
        stackInfo = load(fullfile(dirs.data,expData(i).sub_dir,'stack_info.mat'));
        subject.ID = expData(i).subjectID;
        key.session_date = datestr(stackInfo.startTime,'yyyy-mm-dd');
        behavior = getRemoteVRData( experiment, subject, key );
        behavior = restrictImgTrials(behavior, expData(i).mainMaze);
        %Synchronize imaging frames with behavioral time basis
        stackInfo = syncImagingBehavior(stackInfo, behavior);
        %Save processed data
        create_dirs(fileparts(mat_file.img_beh(i))); %Create save directory
        if ~exist(mat_file.img_beh(i),'file')
            save(mat_file.img_beh(i),'-struct','behavior');
        else
            save(mat_file.img_beh(i),'-struct','behavior','-append');
        end
        save(mat_file.img_beh(i),'-struct','stackInfo','-append');
    end
    clearvars -except data_dir dirs expData calculate summarize figures mat_file params;
end

%% ANALYZE CELLULAR FLUORESCENCE

if calculate.fluorescence
    tic; %Reset timer
    disp(['Processing cellular fluorescence data. ' int2str(numel(expData)) ' sessions total.']);
    f = waitbar(0,'');
    for i = 1:numel(expData)
        %Display waitbar
        msg = ['Session ' num2str(i) '/' num2str(numel(expData)) '...'];
        waitbar(i/numel(expData),f,msg);

        %Load behavioral data and metadata from image stacks
        expData(i).img_beh = load(mat_file.img_beh(i),...
            'ID','imageHeight','imageWidth','nFrames','trialData','trials','t'); %Load saved data

        if calculate.cellF
            %Get cellular and neuropil fluorescence excluding overlapping regions and n-pixel frame
            cells = get_roiData(fullfile(dirs.data,expData(i).sub_dir,expData(i).roi_dir));
            [cells, masks] = calc_cellF(cells, expData(i), params.fluo.exclBorderWidth);
            save(mat_file.img_beh(i),'-struct','cells','-append'); %Save to dff.mat
            save(mat_file.img_beh(i),'masks','-append'); %Save to dff.mat
            clearvars stack cells masks;
        end

        % Calculate dF/F trace for each cell
        if calculate.dFF
            cells = load(mat_file.img_beh(i),'cellID','cellF','npF','frameRate'); %calc_dFF() will transfer any other loaded variables to struct 'dFF'
            cells = calc_dFF(cells, expData(i).npCorrFactor); %expData(i).npCorrFactor set to zero for prelim analysis
            save(mat_file.img_beh(i),'-struct','cells','-append');
            clearvars cells
        end

        % Align dF/F traces to specified behavioral event
        if calculate.align_signals
            cells = load(mat_file.img_beh(i),'dFF','t');
            load(mat_file.img_beh(i),'trials','trialData','sessions');
            trialDFF = alignCellFluo(cells,trialData.eventTimes,params.align);
            params.align.lCue = sessions.lCue;
            [trialDFF.cueRegion, trialDFF.position] = ...
                alignFluoByPosition(cells,trialData,params.align);
            save(mat_file.img_beh(i),'trialDFF','-append');
            clearvars cells trials trialData trialDFF
        end

        % Event-related cellular fluorescence
        if calculate.trial_average_dFF %Trial averaged dF/F with bootstrapped CI
            load(mat_file.img_beh(i),'trialDFF','trials','cellID');
            for j = 1:numel(params.bootAvg)
                bootAvg.(params.bootAvg(j).trigger) = calc_trialAvgFluo(trialDFF, trials, params.bootAvg(j));
            end
            if ~exist(mat_file.results(i),'file')
                save(mat_file.results(i),'bootAvg','cellID'); %Save
            else, save(mat_file.results(i),'bootAvg','cellID','-append');
            end
        end

        % Decode choice, outcome, and rule from single-units
        if calculate.decode_single_units
            load(mat_file.img_beh(i),'trialDFF','trials');
            decode = calc_selectivity(trialDFF,trials,params.decode);
            save(mat_file.results(i),'decode','-append');
        end

    end
    close(f);
    disp(['Total time needed for cellular fluorescence analyses: ' num2str(toc) 'sec.']);
    %05 hrs for cellF
    %29 hrs for dF/F for all sessions
    %XX hrs for new ROC analysis

end

%% SUMMARY

%***FUTURE: Save reference table

% Behavior
if summarize.behavior
    fieldNames = {'sessionData','trialData','trials','blocks','cellType'};
    B = initSummaryStruct(mat_file.behavior,[],fieldNames,expData); %Initialize data structure
    behavior = summary_behavior(B, params.behavior); %Aggregate results
    save(mat_file.summary.behavior,'-struct','behavior');
end

% Imaging
if summarize.imaging
    fieldNames = {'sessionID','cellID','exclude','blocks','trials','trialDFF'};
    S = initSummaryStruct(mat_file.img_beh,[],fieldNames,expData); %Initialize data structure
    imaging = summary_imaging(S, params.bootAvg); %Aggregate results
    save(mat_file.summary.imaging,'-struct','imaging');
end

% Selectivity
if summarize.selectivity
    %Initialize structure
    for i=1:numel(params.decode.decode_type)
        selectivity.(params.decode.decode_type{i}) = struct();
    end
    %Aggregate results
    for i = 1:numel(expData)
        S = load(mat_file.results(i),'decode','cellID');
        selectivity = summary_selectivity(...
            selectivity, S.decode, expData(i).cellType, i, S.cellID, params.decode); %summary = summary_selectivity( summary, decode, cell_type, exp_ID, cell_ID, params )
    end
    selectivity.t = S.decode.t; %Copy time vector from 'decode'
    save(mat_file.summary.selectivity,'-struct','selectivity');
end

% Summary Statistics and Results Table
if summarize.stats
    %Initialize file
    analysis_name = params.stats.analysis_names;
    if ~exist(mat_file.stats,'file')
        for i = 1:numel(analysis_name)
            stats.(analysis_name{i}) = struct();
        end
        save(mat_file.stats,'-struct','stats');
    end

    %Load summary data from each analysis and calculate stats
    stats = load(mat_file.stats);
    for i = 1:numel(analysis_name)
        summary = load(mat_file.summary.(analysis_name{i}));
        stats = summary_stats(stats,summary,analysis_name{i});
    end
    save(mat_file.stats,'-struct','stats');
end

% Stop logging processes
diary off;

%% SUMMARY TABLES
if summarize.table_experiments
    % SessionID, CellType, #Cells, #Trials, #Blocks, #Cells_included, #Cells_excluded
    stats = load(mat_file.stats,'behavior','imaging','tables');
    tables.summary = table_expData(expData,stats);
    save(mat_file.stats,'tables','-append');
    writetable(tables.summary,...
        fullfile(dirs.summary,'Table_Experiments.xls'),'WriteRowNames',true);
end

if summarize.table_descriptive_stats
    stats = load(mat_file.stats,'behavior','imaging','selectivity');
    [tables.descriptiveStats, tabular.descriptiveStats] = table_descriptiveStats(stats); %Might not need tabular...
    save(mat_file.stats,'tabular','tables','-append');
    writetable(tables.descriptiveStats,...
        fullfile(dirs.summary,'Table_Descriptive_Stats.xls'),'WriteRowNames',true);
end

if summarize.table_comparative_stats
    stats = load(mat_file.stats);
    [tables, tabular] = table_comparisons(stats); %[p,tbl,stats] = kruskalwallis(x,{'SST','VIP','PV','PYR'},displayopt);
    save(mat_file.stats,'tabular','tables','-append');
    writetable(tables.comparisons,...
        fullfile(dirs.summary,'Table_Comparisons.xls'),'WriteRowNames',true);
    writetable(tables.multiple_comparisons,...
        fullfile(dirs.summary,'Table_Multiple_Comparisons.xls'),'WriteRowNames',true);
end

%% FIGURES

figures_TaskLearning_VTA1; %In a separate script for brevity.