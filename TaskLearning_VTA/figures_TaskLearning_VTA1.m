%%% ALL FIGURES FOR STUDY ON CELL TYPES RECORDED DURING FLEXIBLE SENSORIMOTOR BEHAVIOR
%
% AUTHOR: MJ Siniscalchi 190701; separated from 'analyze_RuleSwitching.m' 200213
%
% NOTE: Use header only if run independently of 'analyze_RuleSwitching.m'
%
%---------------------------------------------------------------------------------------------------
% clearvars;

% Set MATLAB path and get experiment-specific parameters
% [dirs, expData] = expData_RuleSwitching(pathlist_RuleSwitching);
% [dirs, expData] = expData_RuleSwitching_DEVO(pathlist_RuleSwitching); %For processing/troubleshooting subsets

% [calculate, summarize, figures, mat_file, params] = params_RuleSwitching(dirs,expData);
% expData = get_imgPaths(dirs, expData, calculate, figures); %Append additional paths for imaging data if required by 'calculate'
% 
% % Begin logging processes
% diary(fullfile(dirs.results,['procLog' datestr(datetime,'yymmdd')])); 
% diary on;
% disp(datetime);


%% FIGURES - IMAGING

% Generate Mean Projection Image for each field-of-view
if figures.FOV_mean_projection
    save_dir = fullfile(dirs.figures,'FOV mean projections');   %Figures directory: cellular fluorescence
    create_dirs(save_dir); %Create dir for these figures
    expIdx = restrictExpIdx({expData.sub_dir},params.figs.fovProj.expIDs); %Restrict to specific sessions, if desired
    
    % Calculate or re-calculate mean projection from substacks
    figData = getFigData(dirs,expData,expIdx,mat_file,'FOV_mean_projections',params);
          
    % Generate figures: mean projection with optional ROI and/or neuropil masks
    figs = gobjects(numel(expIdx),1); %Initialize figures
    for i = 1:numel(expIdx)
        figs(i) = fig_meanProj(figData, expIdx(i), params.figs.fovProj); %***WIP***
        figs(i).Name = expData(expIdx(i)).sub_dir;
        if ~isempty(params.figs.fovProj.cellIDs)
            figs(i).Name = [expData(expIdx(i)).sub_dir,'_ROIs'];
        end
    end
    save_multiplePlots(figs,save_dir,'pdf'); %Save figure
end

% Plot all timeseries from each experiment
if figures.timeseries
    %Initialize graphics array and create directories 
    expIdx = restrictExpIdx({expData.sub_dir},params.figs.timeseries.expIDs); %Restrict to specific sessions, if desired 
    save_dir = fullfile(dirs.figures,'Cellular fluorescence');   %Figures directory: cellular fluorescence
    create_dirs(save_dir); %Create dir for these figures 
    figs = gobjects(numel(expIdx),1); %Initialize figures
    %Generate figures
    for i = 1:numel(expIdx)
        imgBeh = load(mat_file.img_beh(expIdx(i)),'dFF','t','trials','trialData','cellID'); %Load data
        imgBeh.sessionID = expData(i).sub_dir;
%         params.figs.timeseries.cellIDs = ["001","005","006","008"];
        figs(i) = fig_plotAllTimeseries(imgBeh,params.figs.timeseries);         %Generate fig
    end
    %Save batch as FIG, PNG, and SVG
    save_multiplePlots(figs,save_dir,'pdf');
    clearvars figs;
end

%% FIGURES - SINGLE UNIT ANALYSES

% Plot trial-averaged dF/F
if figures.trial_average_dFF
    for i = 1:numel(expData)
        %Load data
        load(mat_file.results(i),'bootAvg','cellID');
        save_dir = fullfile(dirs.figures,'Cellular fluorescence',expData(i).sub_dir);   %Figures directory: single units
        create_dirs(save_dir); %Create dir for these figures
        %Save figure for each cell plotting all combinations of choice x outcome
        comparisons = unique([params.figs.bootAvg.panels.comparison],'stable');
        for j = 1:numel(comparisons)
            panelIdx = find([params.figs.bootAvg.panels.comparison]==comparisons(j));
            event = [params.figs.bootAvg.panels(panelIdx(1)).trigger];
            figs = plot_trialAvgDFF(bootAvg.(event),cellID,expData(i).sub_dir,params.figs.bootAvg.panels(panelIdx));
            save_multiplePlots(figs,save_dir);%,'pdf'); %save as FIG and PNG
        end
        clearvars figs
    end
end

if figures.time_average_dFF
    expIdx = restrictExpIdx({expData.sub_dir},params.figs.timeAvg.expIDs); %Restrict to specific sessions, if desired 
    cellIDs = restrictCellIDs(expIdx,params.figs.timeAvg.cellIDs); %Cell array of subsets 
    for i = expIdx
        %Load data
        load(mat_file.results(i),'bootAvg');
        %Get specified subset of cells
        cellIdx = getCellSubset(mat_file.img_beh(i),cellIDs{expIdx==i});
        save_dir = fullfile(dirs.figures,'Cellular fluorescence');   %Figures directory: single units
        create_dirs(save_dir); %Create dir for these figures
        
        %Save figure for each cell plotting all combinations of choice x outcome
        fig = plot_timeAvgDFF(bootAvg, cellIdx,...
            expData(i).sub_dir, expData(i).cellType, params.figs.timeAvg);
        save_multiplePlots(fig,save_dir,'pdf'); %save as FIG, PNG & PDF
        clearvars fig
     end
end

% Heatmap of selectivity traces: one figure each for choice, outcome, and rule
if figures.summary_selectivity_heatmap
    %Load data
    S = load(mat_file.summary.selectivity);
    for rule = ["sensory","alternation"]
        figs = heatmap_summarySelectivity(S.(rule), join(["selectivity_heatmap_" rule],''), params.summary.trialAvg);
        save_multiplePlots(figs,save_dir); %save as FIG and PNG
        clearvars figs;
    end
end