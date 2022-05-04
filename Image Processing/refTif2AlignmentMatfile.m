%
%
%---------------------------------------------------------------------------------------------------
clearvars;

save_suffix = 'alignment';
data_dir = uigetdir('C:\Data\2-Photon Imaging\Ref Image Batch');
[dirs, paths, stackInfo, params] = getRegData(data_dir);
ref_img = getRefImg(paths.mat,stackInfo,params.nFrames_seed);

[file,path] = uigetfile();
S = load(fullfile(path,file));
S.lclReferenceData.roiDat.displayData = int32(ref_img);


