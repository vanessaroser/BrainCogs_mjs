data_dir = 'Y:\michael\_technical\221223-2p-grin-lens\bead1-drift-920';
crop_margins = [0,0,512];

%Get mean projection of each slice (1 TIFF/slice)
fileList = dir(fullfile(data_dir,'*.tif'));
fname = string({fileList(:).name}');

%Load all tiffs, get z-projection, and determine margins for cropping
%eg, smooth and use max +/-  

nX = crop_margins(3); % crop_margins:=[top, left, box_width]
nY = crop_margins(3);
nZ = numel(fileList);

slices = NaN(nX,nY,nZ); %Pre-allocate memory with hard-coded XY dimensions
if numel(fileList)>1
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
    [stack, tags] = loadtiffseq(fullfile(data_dir,fname(i)));
    slices(:,:,i) = mean(cropStack(stack,crop_margins),3,"omitnan"); %Obtain mean projection across frames
end

save_path = fullfile(fileparts(data_dir),'meanProjections.tif');
saveTiff( int16(slices), tags, save_path );