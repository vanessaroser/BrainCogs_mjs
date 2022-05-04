%%% get_roiData()
%
% PURPOSE: ROIs selected using cellROI.m, along with optional neuropil masks.
%
% AUTHOR: MJ Siniscalchi, Princeton Neuroscience Institute, 220421
%           simplified from previous version
%
% INPUT ARGS: 
%           char 'roi_path', the path to a directory containing all ROI files,
%               as well as the MAT file 'roiData.mat'. All files generated
%               using the GUI, cellROI.m.
%
% OUTPUTS: 
%         struct 'cells' containing these fields:           
%           'cellMasks', an X x Y x nROIs logical array containing the logical indices for each ROI.
%           'subtractMasks', the same for each neuropil mask, if desired. 
%           'cellIDs', an array of character vectors corresponding to 
%               the cell IDs from cellROI; also found in the filenames.
%
%--------------------------------------------------------------------------
     
function cells = get_roiData( roi_path )

% Populate structure with data from ROI files generated by cellROI.m
fileList = dir(fullfile(roi_path,'*cell*.mat'));
fileIDs = {};
for j = 1:numel(fileList)
    S = load(fullfile(roi_path, fileList(j).name));
    cells.cellMask{j} = S.bw;
    cells.cellID{j} = num2str(fileList(j).name(end-6:end-4));
    if isfield(S,'subtractmask')
        cells.npMask{j} = S.subtractmask;
    else
        cells.npMask{j} = false(size(S.bw));
        fileIDs{numel(fileIDs)+1} = fileList(j).name(end-6:end-4);
    end
    cells.exclude(j) = isempty(S.cellf); %Exclusion masks generated by 'cellROI.m' are coded with cellf = [].
end

if ~isempty(fileIDs)
    warning('on'); warning('backtrace','off');
    warning('No neuropil masks found in the following files:');
    disp(fileIDs');
end