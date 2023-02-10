function [ offset, img ] = estimatePeakDistance( data_dir, crop_margins, perctile_thresh, um_per_pixel )

tic;
%Get mean projection of each slice (1 TIFF/slice)
fileList = dir(fullfile(data_dir,'*.tif'));
fname = string({fileList(:).name}');

%Load all tiffs, get z-projection, and determine margins for cropping
%eg, smooth and use max +/-

if numel(fileList)>1
    nX = crop_margins(3); % crop_margins:=[top, left, box_width]
    nY = crop_margins(3);
    nZ = numel(fileList);
    slices = NaN(nX,nY,nZ); %Pre-allocate memory with hard-coded XY dimensions
    parfor i = 1:nZ
        %[ stack, tags, ImageDescription ] = loadtiffseq( full_path, channel, method )
        if i==1
            [stack, tags(i)] = loadtiffseq(fullfile(data_dir,fname(i)));
            slices(:,:,i) = mean(cropStack(stack,crop_margins),3,"omitnan"); %Obtain mean projection across frames
        else
            stack = cropStack(loadtiffseq(fullfile(data_dir,fname(i))),crop_margins);
            slices(:,:,i) = mean(stack,3,"omitnan"); %Obtain mean projection across frames
        end
    end
else
    [stack, tags] = loadtiffseq(fullfile(data_dir,fname));
    if numel(crop_margins)==1 %Only box-width specified
        %Crop to box of spec width around max pixel in smoothed z-projection
        zProj = imgaussfilt(mean(stack,3),2);
        [y,x] = find(zProj==max(zProj,[],"all"));
        crop_margins = [y-0.5*crop_margins, x-0.5*crop_margins, crop_margins];
    end
    slices = cropStack(stack,crop_margins); %Obtain mean projection across frames
    [nY,nX,nZ] = size(slices);
end
%Adjust tags
tags.ImageLength = nY;
tags.ImageWidth = nX;

%Calculate X, Y, and Z mean projection and profile
dim = [1,2,3];
ax = ["y","x","z"];
for i = 1:numel(ax)
    %Convert pixels to microns and store
    X = double(0:size(slices,i)-1); %**for Z: Assumes 1-um step size for z-stack**
    if ismember(ax(i),["x","y"])
        X = X * um_per_pixel; %X-Y Position
        meanProj.(ax(i)).X = X;
        meanProj.(ax(i)).Y = 0:nZ-1; %Depth
        %Take mean over the relevant spatial dimension(s)
        meanProj.(ax(i)).data = squeeze(mean(slices,i))'; %Transpose eg Y-Z to make depth dim 1
    else %Z
        meanProj.z.X = (0:nX-1)*um_per_pixel;  %X-Y Position
        meanProj.z.Y = (0:nY-1)*um_per_pixel;  %X-Y Position
        %Take mean over z-axis
        meanProj.(ax(i)).data = squeeze(mean(slices,i));
    end
    profile.(ax(i)).X = X; %X-Y Position
    data(:,1) = squeeze(mean(slices,dim(dim~=i))); %Axis profile
    profile.(ax(i)).data = (data-min(data))./range(data); %Peak normalize
    clearvars data
end

% Estimate peaks in dual-wavelength zPSF based on smoothed and thresholded z-projection
%Smooth and threshold
meanProj.z.smoothed = imgaussfilt(meanProj.z.data, 1.5);
bw = meanProj.z.smoothed >= prctile(meanProj.z.smoothed,perctile_thresh,'all');
%Get largest region (which should represent the 1-um bead)
regions = bwconncomp(bw,4); %Find regions with 4-connectivity
nPix = cellfun(@numel,regions.PixelIdxList); %Number of pixels in each region
largestRegion = nPix==max(nPix); %Largest region
%Index all voxels belonging to bead
xyMask = false(size(bw));
xyMask(regions.PixelIdxList{largestRegion})=true;
beadVoxels = slices(repmat(xyMask,1,1,nZ)); %xyMask across all slices
%Extract voxels as 2D matrix and take mean
offset.z.data = mean(reshape(beadVoxels,sum(xyMask,'all'),nZ)); %reshaped as masked pixels x slice

%Generate smooth intensity as a function of depth and get distance between peaks
%Recenter values so lowPercentile(X)=0
data = offset.z.data(:)'; %Make row vector for plotting
data = (data-min(data))./range(data);

%Smooth/fit
X = profile.z.X;
smoothed = smooth(data, 3); %Smoothed data
gaussian = fit(X(:), data(:), 'gauss2'); %Fit with 2nd-order Gaussian; keep cfit object for feval() in figures

%Find peaks in Smoothed Axial Data
% figure
% findpeaks(...
%     smoothed, X, 'WidthReference', 'halfheight', 'NPeaks', 2, 'SortStr', 'descend','MinPeakProminence',0.02,'Annotate','peaks');

[peak, loc] = findpeaks(...
    smoothed, X, 'WidthReference', 'halfheight', 'MinPeakProminence', 0.02, 'NPeaks', 2, 'SortStr', 'descend');
offset.z = struct(...
    "data",data,"X",X,"smoothed",smoothed,"gaussian",gaussian,"peak",peak,"loc",loc,"diff",abs(diff(loc)));

%Find peaks in Z-projection and get x- and y-offsets
P = 80; %Starting percentile for pixel intensity
nPix = 25; %minimal nPixels in each region
nRegions=0; %Number of regions found
while P<100 && nRegions<2 
    bw = meanProj.z.smoothed >= prctile(meanProj.z.smoothed, P, 'all');
    %Get largest region (which should represent the 1-um bead)
    regions = bwconncomp(bwareaopen(bw,nPix),4); %Find regions with 4-connectivity
    [~,idx] = sort(cellfun(@numel,regions.PixelIdxList),"descend"); %Number of pixels in each region
    if numel(regions.PixelIdxList) > 1
        PixelIdxList = regions.PixelIdxList(idx(1:2)); %Restrict to two largest regions
        nRegions = numel(PixelIdxList);
    end
    P = P+0.1; %Increment the percentile until regions separate
end
% bw = meanProj.z.smoothed >= prctile(meanProj.z.smoothed, 95, 'all');
% figure; imagesc(meanProj.z.smoothed);
% figure; imagesc(bw);
clearvars data idx smoothed

% Determine X- and Y- offsets
if nRegions==2
stats = regionprops(regions);
centroids = reshape([stats(:).Centroid],[2,2]); %1 column [X;Y] per region

%Average across 3 rows for X and 3 col for Y
ax = ["x","y"];
idx.x = {...
    {round(centroids(2,1))+[-1,0,1], 1:size(meanProj.z.data,2)};...
    {round(centroids(2,2))+[-1,0,1], 1:size(meanProj.z.data,2)}};
idx.y = {...
    {(1:size(meanProj.z.data,1))',round(centroids(1,1))'+[-1,0,1]};
    {(1:size(meanProj.z.data,1))',round(centroids(1,2))'+[-1,0,1]}};
for i = 1:numel(ax)
    X = profile.(ax(i)).X;
    for j = 1:numel(stats) %for each centroid 
        %Use Mean across three rows(X) or columns(Y)
        values = meanProj.z.data(idx.(ax(i)){j}{1},idx.(ax(i)){j}{2});
        if size(values,1)>size(values,2)
            values = values'; %Transpose
        end
        data(j,:) = mean(values,1);
        data(j,:) = (data(j,:)-min(data(j,:)))./range(data(j,:)); %Normalize [0,1]
        smoothed(j,:) = smooth(data(j,:),10); %Smoothe before peak-finding
        [peak(j), loc(j)] = findpeaks(...
            smoothed(j,:), X, 'WidthReference', 'halfheight', 'NPeaks', 1, 'SortStr', 'descend');
    end
    offset.(ax(i)) = struct(...
    "data", data,"smoothed", smoothed,"peak",peak(:)',"loc",loc(:)',"diff", diff(loc),"X",X);
end
end

img = struct("slices", slices, "meanProj", meanProj, "profile", profile, "xyMask", xyMask, "tags",tags);