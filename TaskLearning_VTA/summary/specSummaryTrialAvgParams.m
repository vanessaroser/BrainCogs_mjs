function params = specSummaryTrialAvgParams(colors)

i = 1;
%Choice aligned to y-position
params(i).comparison = "choice_cueRegion";
params(i).trigger = "cueRegion";
params(i).trialSpec = ["left", "right"]; %(type2-type1)/|type2|+|type1|
%For figure
params(i).title         = "Choice";
params(i).window        = [-50, 90]; %Window for across-trial averaging
params(i).avgWindow     = [0, 90]; %Window for within-trial averaging
params(i).edges         = [-inf, -0.2:0.01:0.2, inf]; %For histogram of selectivity
params(i).color         = {colors.left, colors.right}; %Choice: left/hit/sound vs right/hit/sound
params(i).lineStyle     = {'-','-'};
% params(i).dataLabel.selectivity = 'Selectivity, |(R-L)/(R+L)|';  % X Axis or Color Axis Label
params(i).dataLabel.selectivity = 'Selectivity';  % X Axis or Color Axis Label
% params(i).dataLabel.preference  = 'Preference, (R-L)/(R+L)';  % X Axis or Color Axis Label
params(i).dataLabel.preference  = 'Preference (L<->R)';  % X Axis or Color Axis Label
params(i).xLabel        = 'Distance (cm)';  % XLabel

i = i+1;
%Prior choice aligned to y-position
params(i).comparison = "priorChoice_cueRegion";
params(i).trigger = "cueRegion";
params(i).trialSpec = ["priorLeft", "priorRight"];
%For figure
params(i).title         = "Prior Choice";
params(i).window        = [-50, 90]; %Window for across-trial averaging
params(i).avgWindow     = [0, 90];
params(i).edges         = [-inf, -0.2:0.01:0.2, inf]; %For histogram of selectivity
params(i).color         = {colors.left,colors.right}; %Choice: left/hit/sound vs right/hit/sound
params(i).lineStyle     = {'-','-'};
params(i).dataLabel.selectivity = 'Selectivity';  % X Axis or Color Axis Label
params(i).dataLabel.preference  = 'Preference (L<->R)';  % X Axis or Color Axis Label
params(i).xLabel        = 'Distance (cm)';  % XLabel

i = i+1;
%Cueside aligned to y-position
params(i).comparison = "cueSide_cueRegion";
params(i).trigger = "cueRegion";
params(i).trialSpec = ["leftCue", "rightCue"];
%For figure
params(i).title         = "Cue Side";
params(i).window        = [-50, 90]; %Window for across-trial averaging
params(i).avgWindow     = [0, 90];
params(i).edges         = [-inf, -0.2:0.01:0.2, inf]; %For histogram of selectivity
params(i).color         = {colors.left,colors.right}; %Choice: left/hit/sound vs right/hit/sound
params(i).lineStyle     = {':',':'};
params(i).dataLabel.selectivity = 'Selectivity';  % X Axis or Color Axis Label
params(i).dataLabel.preference  = 'Preference (L<->R)';  % X Axis or Color Axis Label
params(i).xLabel        = 'Distance (cm)';  % XLabel

i = i+1;
%Prior outcome aligned to y-position in rewarded trials
params(i).comparison = "accuracy_cueRegion";
params(i).trigger = "cueRegion";
params(i).trialSpec = ["error","correct"];
%For figure
params(i).title         = "Accuracy";
params(i).window        = [-50, 90]; %Window for across-trial averaging
params(i).avgWindow     = [0, 90];
params(i).edges         = [-inf, -0.2:0.02:0.6, inf]; %For histogram of selectivity
params(i).color         = {colors.correct,colors.err}; %Choice: left/hit/sound vs right/hit/sound
params(i).lineStyle     = {'-','-'};
params(i).dataLabel.selectivity = 'Selectivity';  % X Axis or Color Axis Label
params(i).dataLabel.preference  = 'Preference (Err<->Rew)';  % X Axis or Color Axis Label
params(i).xLabel        = 'Distance (cm)';  % XLabel

i = i+1;
%Prior outcome aligned to y-position in rewarded trials
params(i).comparison = "priorOutcome_cueRegion";
params(i).trigger = "cueRegion";
params(i).trialSpec = ["priorError","priorCorrect"];
%For figure
params(i).title         = "Prior Outcome";
params(i).window        = [-50, 90]; %Window for across-trial averaging
params(i).avgWindow     = [0, 90];
params(i).edges         = [-inf, -0.2:0.02:0.6, inf]; %For histogram of selectivity
params(i).color         = {colors.correct, colors.err}; %Choice: left/hit/sound vs right/hit/sound
params(i).lineStyle     = {'-','-'};
params(i).dataLabel.selectivity = 'Selectivity';  % X Axis or Color Axis Label
params(i).dataLabel.preference  = 'Preference (Err<->Rew)';  % X Axis or Color Axis Label
params(i).xLabel        = 'Distance (cm)';  % XLabel

% i = i+1;
% %All activity aligned to y-position in rewarded trials
% params(i).comparison = "position_cueRegion";
% params(i).trigger = "cueRegion";
% params(i).trialSpec = ["forward"];
% %For figure
% params(i).title         = "Position";
% params(i).window        = [-50, 90];
% params(i).color         = {colors.data}; %Choice: left/hit/sound vs right/hit/sound
% params(i).lineStyle     = {'-','-'};
% params(i).cLabel        = 'zscore(dF/F)';  % Color Axis Label
% params(i).xLabel        = 'Distance (cm)';  % XLabel

% %Append general params
% fields = fieldnames(generalParams);
% for j = 1:numel(fields)
%     [params(1:i).(fields{j})] = deal(generalParams.(fields{j}));
% end

