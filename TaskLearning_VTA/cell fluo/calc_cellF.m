%%% calcCellF
%
%PURPOSE: To adjust cellF based on two spatial exclusions:
%       1.) Overlapping regions of multiple ROIs are excluded.
%       2.) An n-pixel width boundary is excluded at the edge of each frame.
%
%AUTHOR: MJ Siniscalchi, 190222
%           -190619mjs Edited to accommodate trial-by-trial movement corrected data...
%
%INPUT ARGS:    struct 'cells', containing these fields:
%                   'roimask', a cell array of logical masks,
%                       each indexing a ROI within the field of view.
%                   'subtractmask', same for the neuropil masks.
%               double 'stack' OR
%               cell   'stack', containing full path to each stack as .MAT
%               double 'borderWidth'
%
%OUTPUTS:
%               struct roiData, with fields:
%                   cellf:      1d cell array containing final cellular fluorescence for each ROI, post processing
%                   neuropilf:  (same for neuropil fluorescence)
%                   roi:        (same for cell masks)
%                   npMask:     (same for neuropil masks)
%
%               struct mask, with fields:
%                   include, exclude: binary arrays containing included/excluded regions
%
%--------------------------------------------------------------------------

function [cells, masks] = calc_cellF( cells, expData, borderWidth )



%Get image info for the series of stacks
nX = expData.img_beh.imageWidth;
nY = expData.img_beh.imageHeight;
nStacks = numel(expData.reg_path);
nFrames = expData.img_beh.nFrames;

%Convert from cell arrays to 3d matrices
cellMasks = cell2mat(cells.cellMask);
cellMasks = reshape(cellMasks,[nY,nX,numel(cells.cellMask)]);
npMasks = cell2mat(cells.npMask);
npMasks = reshape(npMasks,[nY,nX,numel(cells.npMask)]);

%Generate inclusion/exclusion masks
masks.include = false(nX,nY); %Initialize
masks.exclude = false(nX,nY);
if nargin > 2
    masks.exclude([(1:borderWidth) (nY-borderWidth+1:nY)],:) = true; %Frame around image: Top and bottom
    masks.exclude(:,[(1:borderWidth) (nX-borderWidth+1:nX)]) = true; %Left and right
end
masks.exclude(sum(cellMasks,3)>1) = true;     %Overlapping Regions of multiple cells
masks.include(sum(cellMasks,3)==1 & ~masks.exclude) = true; %Logical idx for all ROIs after exclusion

%% Get cellular and neuropil fluorescence, excluding Frame and Overlapping regions

% Remove entries for cells excluded in cellROI.m
cellMasks = cellMasks(:,:,~cells.exclude); %Exclude exclusion masks
cells.cellID = cells.cellID(~cells.exclude);
cells.cellID = cells.cellID(:);
cells = rmfield(cells,'exclude');

disp(['Getting cellular and neuropil fluorescence, excluding '...
    num2str(borderWidth) '-pixel frame and overlapping regions...']);

% Pre-allocate memory and define spatial masks
cellf =     cell([size(cellMasks,3),1]);
neuropilf = cell([size(cellMasks,3),1]);
roi =       cell([size(cellMasks,3),1]);
npMask =    cell([size(cellMasks,3),1]);

for j = 1:numel(roi)
    cellf{j} = NaN(sum(nFrames),1);
    neuropilf{j} = NaN(sum(nFrames),1);
    roi{j} = logical(cellMasks(:,:,j) & ~masks.exclude); %Cell mask from cellROI, excluding specified regions
    npMask{j} = logical(npMasks(:,:,j) & ~masks.exclude); %Neuropil mask from cellROI, excluding specified regions
end

% Get mean fluorescence within each ROI and neuropil mask, for each frame
%ScanImageTiffReader now 10x faster than loading pre-saved MAT files containing stacks
for i = 1:nStacks
    S = loadtiffseq(expData.reg_path{i}); %Load registered stack
    idx = sum(nFrames(1:i))-nFrames(i)+1 : sum(nFrames(1:i)); %startIdx : endIdx
    for j = 1:numel(idx)
        img = S(:,:,j); %single frame
        for k = 1:numel(roi)
            cellf{k}(idx(j))     = mean(img(roi{k})); %mean pixel value within ROI
            neuropilf{k}(idx(j)) = mean(img(npMask{k})); %same for neuropil mask
        end
    end
    disp(['Frame ' num2str(idx(end)) '/' num2str(sum(nFrames))]);
    clearvars S
end

%Store in structure
cells.cellF = cellf;
cells.npF = neuropilf;
cells.t = expData.img_beh.t;
cells.cellMask = roi;
cells.npMask = npMask;


