clearvars;

i=1;

% %Y:\michael\_technical\230111-2p-beads\bead1-dualWL
% dir_str = ["Y:","michael","_technical","230111-2p-beads","bead1-dualWL"];
% exp(i).dir = fullfile(dir_str{:});
% exp(i).sessionID = join(dir_str(end-1:end),'-');
% exp(i).depth = -2225-(-2500); %**Not recorded; used midway between 920 and 1064 coordinate**
% exp(i).um_per_pixel = 70/512;
% exp(i).crop_margins = [225,189,80];
% i=i+1;
% 
% %Y:\michael\_technical\230112-2p-beads\bead1-dualWL
% dir_str = ["Y:","michael","_technical","230112-2p-beads","bead1-dualWL"];
% exp(i).dir = fullfile(dir_str{:});
% exp(i).sessionID = join(dir_str(end-1:end),'-');
% exp(i).depth = -2025-(-2700); 
% exp(i).um_per_pixel = 70/512;
% exp(i).crop_margins = [227,223,60];
% i=i+1;
% 
% %Y:\michael\_technical\230112-2p-beads\bead2-dualWL
% dir_str = ["Y:","michael","_technical","230112-2p-beads","bead2-dualWL"];
% exp(i).dir = fullfile(dir_str{:});
% exp(i).sessionID = join(dir_str(end-1:end),'-');
% exp(i).depth = -2025-(-2700); 
% exp(i).um_per_pixel = 70/512;
% exp(i).crop_margins = [237,238,60];
% i=i+1;
% 
% %Y:\michael\_technical\230112-2p-beads\bead3-dualWL
% dir_str = ["Y:","michael","_technical","230112-2p-beads","bead3-dualWL"];
% exp(i).dir = fullfile(dir_str{:});
% exp(i).sessionID = join(dir_str(end-1:end),'-');
% exp(i).depth = -2025-(-2700); 
% exp(i).um_per_pixel = 70/512;
% exp(i).crop_margins = [243,226,60];
% i=i+1;
% 
% %Y:\michael\_technical\230112-2p-beads-noGRInLens\bead1-dualWL
% dir_str = ["Y:","michael","_technical","230112-2p-beads-noGRInLens","bead1-dualWL"];
% exp(i).dir = fullfile(dir_str{:});
% exp(i).sessionID = join(dir_str(end-1:end),'-');
% exp(i).depth = -2025-(-2700); 
% exp(i).um_per_pixel = 70/512;
% exp(i).crop_margins = [208,229,60];
% i=i+1;

data_dir = "Y:\michael\_technical\230203-leica-nogrinlens\bead2-dualWL";
dir_str = split(data_dir,filesep)';
exp(i).dir = fullfile(dir_str{:});
exp(i).sessionID = join(dir_str(end-1:end),'-');
exp(i).depth = NaN; 
exp(i).um_per_pixel = 62/256;
exp(i).crop_margins = 60;
i=i+1;

%Y:\michael\_technical\230112-2p-beads\bead1-dualWL
%Y:\michael\_technical\230112-2p-beads\bead2-dualWL
%Y:\michael\_technical\230112-2p-beads\bead3-dualWL
%Y:\michael\_technical\230112-2p-beads-noGRInLens\bead1-dualWL

%% Loop through all datasets
for i=1:numel(exp)
    %Estimate PSF
    [ offset, img ] =...
        estimatePeakDistance( exp(i).dir, exp(i).crop_margins, 95, exp(i).um_per_pixel);
    %Generate figure and save
    fig = plotAxialOffset(offset, img, exp(i).sessionID);
    save_dir = fileparts(exp(i).dir); %Save in main data dir
    save_multiplePlots(fig, save_dir);
    %Save results and metadata
    expData = exp(i);
    save(fullfile(save_dir,exp(i).sessionID),'offset','img');
    save(fullfile(save_dir,exp(i).sessionID),'-struct','expData','-append');
end