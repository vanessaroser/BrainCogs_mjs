function params = specSummaryTrialAvgParams(colors)

i = 1;
%Choice aligned to y-position
params(i).comparison = "choice_cueRegion";
params(i).trigger = "cueRegion";
params(i).trialSpec = ["left", "right"];
%For figure
params(i).title         = "Choice Selectivity";
params(i).window        = [-50, 90];
params(i).color         = {colors.left, colors.right}; %Choice: left/hit/sound vs right/hit/sound
params(i).lineStyle     = {'-','-'};
params(i).cLabel        = '(R-L)/(R+L)';  % Color Axis Label
params(i).xLabel        = 'Distance (cm)';  % XLabel

i = i+1;
%Cueside aligned to y-position
params(i).comparison = "cueSide_cueRegion";
params(i).trigger = "cueRegion";
params(i).trialSpec = ["leftCue", "rightCue"];
%For figure
params(i).title         = "Cue Selectivity";
params(i).window        = [-50, 90];
params(i).color         = {colors.left2,colors.right2}; %Choice: left/hit/sound vs right/hit/sound
params(i).lineStyle     = {':',':'};
params(i).cLabel        = '(R-L)/(R+L)';  % Color Axis Label
params(i).xLabel        = 'Distance (cm)';  % XLabel

i = i+1;
%Prior outcome aligned to y-position in rewarded trials
params(i).comparison = "priorOutcome_cueRegion";
params(i).trigger = "cueRegion";
params(i).trialSpec = ["correct_priorError", "correct_priorCorrect"];
%For figure
params(i).title         = "Prior Outcome";
params(i).window        = [-50, 90];
params(i).color         = {colors.correct,colors.err}; %Choice: left/hit/sound vs right/hit/sound
params(i).lineStyle     = {'-','-'};
params(i).cLabel        = '(Rew-Err)/(Rew+Err)';  % Color Axis Label
params(i).xLabel        = 'Distance (cm)';  % XLabel

i = i+1;
%All activity aligned to y-position in rewarded trials
params(i).comparison = "position_cueRegion";
params(i).trigger = "cueRegion";
params(i).trialSpec = ["forward"];
%For figure
params(i).title         = "Position";
params(i).window        = [-50, 90];
params(i).color         = {colors.data}; %Choice: left/hit/sound vs right/hit/sound
params(i).lineStyle     = {'-','-'};
params(i).cLabel        = 'zscore(dF/F)';  % Color Axis Label
params(i).xLabel        = 'Distance (cm)';  % XLabel

% %Append general params
% fields = fieldnames(generalParams);
% for j = 1:numel(fields)
%     [params(1:i).(fields{j})] = deal(generalParams.(fields{j}));
% end

