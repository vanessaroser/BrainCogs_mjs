%---------------------------------------------------------------------------------------------------
% analyze_TaskLearning_VTA1
%
% PURPOSE: To analyze simultaneous Ca++ imaging and virtual maze running behavior.
%
% AUTHOR: MJ Siniscalchi, Princeton Neuroscience Institute, 230918
%
% NOTES:
%           * If neuropil (background) masks are not generated after cell selection in cellROI.m,
%               use the script get_neuropilMasks_script to generate them post-hoc
%               (much faster than doing it through the GUI...).
%
%---------------------------------------------------------------------------------------------------

function Analyze_Tactile2Visual_VTA( search_filter )

% Set path
dirs = getRoots();
addGitRepo(dirs,'General','iCorre-Registration','BrainCogs_mjs','TankMouseVR','U19-pipeline-matlab',...
    'datajoint-matlab','compareVersions','GHToolbox');
addpath(genpath(fullfile(dirs.code, 'mym', 'distribution', 'mexa64')));

% Session-specific metadata
[dirs, expData] = expData_Tactile2Visual_VTA(dirs);
expData = expData(contains({expData(:).sub_dir}', search_filter)); %Filter by data-directory name, etc.

% Set parameters for analysis
experiment = 'mjs_tactile2visual'; %If empty, fetch data from all experiments
[calculate, summarize, figures, mat_file, params] = params_Tactile2Visual_VTA(dirs, expData);
expData = get_imgPaths(dirs, expData, calculate, figures); %Append additional paths for imaging data if required by 'calculate'

% Generate directory structure
create_dirs(dirs.results,dirs.summary,dirs.figures);

% Begin logging processes
diary(fullfile(dirs.results,['procLog' datestr(datetime,'yymmdd')]));
diary on;
disp(datetime);

% Connect to DataJoint
setupDataJoint_mjs();

%% SETUP PARALLEL POOL FOR FASTER PROCESSING
if isempty(gcp('nocreate'))
    try
        parpool([1 128])
    catch err
        warning(err.message);
    end
end

%% CHECK DATA CONSISTENCY AND INITIALIZE FILE FOR COMBINED IMAGING-BEHAVIOR DATA
if calculate.combined_data
    for i = 1:numel(expData)
        %Run basic behavioral processing for each imaging session
        stackInfo = load(fullfile(dirs.data,expData(i).sub_dir,'stack_info.mat'));
        subject.ID = expData(i).subjectID;
        key.session_date = datestr(stackInfo.startTime,'yyyy-mm-dd');
        behavior = getRemoteVRData( experiment, subject, key );
        behavior = restrictImgTrials(behavior, expData(i).mainMaze, expData(i).excludeBlock);
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
    clearvars -except search_filter data_dir dirs expData calculate summarize figures mat_file params;
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
            cells = load(mat_file.img_beh(i),'cellID','cellF','npF','t','frameRate'); %calc_dFF() will transfer any other loaded variables to struct 'dFF'
            cells = calc_dFF(cells, expData(i).npCorrFactor); %expData(i).npCorrFactor set to zero for prelim analysis
            save(mat_file.img_beh(i),'-struct','cells','-append');
            clearvars cells
        end

        % Align dF/F traces to specified behavioral event
        if calculate.align_signals
            cells = load(mat_file.img_beh(i),'dFF','t');
            load(mat_file.img_beh(i),'trialData');
            trialDFF = alignCellFluo(cells, trialData.eventTimes, params.align);
            [trialDFF.cueRegion, trialDFF.position] = ...
                alignFluoByPosition(cells, trialData, params.align);
            save(mat_file.img_beh(i),'trialDFF','-append');
            clearvars cells trialData trialDFF
        end

        % Event-related cellular fluorescence
        if calculate.trial_average_dFF %Trial averaged dF/F with bootstrapped CI
            load(mat_file.img_beh(i),'trialDFF','trials','cellID');
            for j = 1:numel(params.bootAvg) %For each trigger event
                if ~exist('bootAvg') || ~isfield(bootAvg, params.bootAvg(j).trigger)
                    bootAvg.(params.bootAvg(j).trigger) = struct();
                end
                bootAvg.(params.bootAvg(j).trigger) = calc_trialAvgFluo(trialDFF, trials,...
                    params.bootAvg(j), bootAvg.(params.bootAvg(j).trigger)); %Include var bootAvg if multiple params.bootAvg use the same trigger (eg, w/o baseline subtraction)
            end

            %Save results
            session = expData(i).sub_dir; %Before running fresh, Stick these lines in <<if ~exist... >>
            subject = expData(i).subjectID;
            if ~exist(mat_file.results(i),'file')
                save(mat_file.results(i),'subject','session','cellID','bootAvg'); %Save
            else, save(mat_file.results(i),'subject','session','cellID','bootAvg','-append');
            end
            clearvars trialDFF trials cellID bootAvg
        end

        % Decode choice, outcome, and rule from single-units
        if calculate.encoding_model
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

if summarize.trialDFF
    idx.sensory = find([expData.mainMaze]==6);
    idx.alternation = find([expData.mainMaze]==7);
    for rule = ["sensory","alternation"]
        for i = 1:numel(idx.(rule))
            S(i) = load(mat_file.results(idx.(rule)(i)),'bootAvg','cellID'); %Mean traces from each session %'subject','session',
        end
        %Temp--Later update results files to include subjectID & sessionID
        for i = 1:numel(idx.(rule)) 
            S(i).subject = expData(idx.(rule)(i)).subjectID;  
            S(i).session = expData(idx.(rule)(i)).sub_dir; 
        end
        
        [trialAvg.(rule), selectivity.(rule)] = getSummaryTrialAvg(S, params.summary.trialAvg);
        save(mat_file.summary.trialAvgDFF,'-struct','trialAvg');
        save(mat_file.summary.selectivity,'-struct','selectivity');
        clearvars S;
    end
end

%% FIGURES

figures_TaskLearning_VTA1(search_filter); %In a separate script for brevity.