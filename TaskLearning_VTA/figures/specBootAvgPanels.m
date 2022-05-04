function ax = specBootAvgPanels( params )

% switch figID
%     case 'bootAvg_choice'
%     case 'bootAvg_cue'
%     case 'bootAvg_outcome'
% end

colors = params.all.colors;

%Specify struct 'ax' containing variables and plotting params for each figure panel:

i=1;
ax(i).title         = "Choice";
ax(i).comparison    = "Choice";
ax(i).trigger       = "cueEntry";
ax(i).trialType     = ["left_correct", "right_correct"];
ax(i).window        = [-3, 7];
ax(i).color         = {colors.left,colors.right}; %Choice: left/hit/sound vs right/hit/sound
ax(i).lineStyle     = {'-','-'};
ax(i).xLabel        = 'Time from cue entry (s)';  % XLabel

i=i+1;
ax(i).title         = "All Forward";
ax(i).comparison    = "Time";
ax(i).trigger       = "cueEntry";
ax(i).trialType     = ["forward"];
ax(i).window        = [-50, 90];
ax(i).color         = {colors.data}; %Choice: left/hit/sound vs right/hit/sound
ax(i).lineStyle     = {'-'};
ax(i).xLabel        = 'Time from cue entry (s)';  % XLabel

i=i+1;
ax(i).title         = "All Forward";
ax(i).comparison    = "Position";
ax(i).trigger       = "cueRegion";
ax(i).trialType     = ["forward"];
ax(i).window        = [-50, 90];
ax(i).color         = {colors.data}; %Choice: left/hit/sound vs right/hit/sound
ax(i).lineStyle     = {'-'};
ax(i).xLabel        = 'Distance (cm)';  % XLabel

i=i+1;
ax(i).title         = 'Rewarded';
ax(i).comparison    = "Prior outcome";
ax(i).trigger       = "outcome";
ax(i).trialType     = ["correct_priorCorrect", "correct_priorError"];
ax(i).window        = [-3, 5];
ax(i).color         = {colors.correct,colors.correct2}; %Outcome: hit/priorHit vs err/priorHit
ax(i).lineStyle     = {'-',':'};
ax(i).xLabel        = 'Time from outcome (s)';  % XLabel

i=i+1;
ax(i).title         = 'Unrewarded';
ax(i).comparison    = "Prior outcome";
ax(i).trigger       = "outcome";
ax(i).trialType     = ["error_priorCorrect", "error_priorError"];
ax(i).window        = [-3, 5];
ax(i).color         = {colors.err,colors.err2}; %Outcome: hit/priorHit vs err/priorHit
ax(i).lineStyle     = {'-',':'};
ax(i).xLabel        = 'Time from outcome (s)';  % XLabel

% i=i+1;
% ax(i).title         = 'Rewarded';
% ax(i).comparison    = "Outcome conflict";
% ax(i).trigger       = "outcome";
% ax(i).trialType     = ["correct_congruent", "correct_conflict"];
% ax(i).window        = [-3, 5];
% ax(i).color         = {colors.err,colors.err2}; %Outcome: hit/priorHit vs err/priorHit
% ax(i).lineStyle     = {'-',':'};
% ax(i).xLabel        = 'Time from outcome (s)';  % XLabel
% 
% i=i+1;
% ax(i).title      = 'Unrewarded';
% ax(i).comparison    = "Outcome conflict";
% ax(i).trigger   = "outcome";
% ax(i).trialType = ["error_congruent", "error_conflict"];
% ax(i).window    = [-3, 5];
% ax(i).color      = {colors.err,colors.err2}; %Outcome: hit/priorHit vs err/priorHit
% ax(i).lineStyle  = {'-',':'};
% ax(i).xLabel = 'Time from outcome (s)';  % XLabel

i=i+1;
ax(i).title      = 'First Cue';
ax(i).comparison   = 'First Cue';
ax(i).trigger   = "firstCue";
ax(i).trialType = ["leftCue_left", "rightCue_left"];
ax(i).window    = [-3, 5];
ax(i).color      = {colors.left,colors.right}; %Outcome: hit/priorHit vs err/priorHit
ax(i).lineStyle  = {'-','-'};
ax(i).xLabel = 'Time from first cue (s)';  % XLabel

i=i+1;
ax(i).title      = 'First Cue';
ax(i).comparison    = 'First Cue';
ax(i).trigger   = "firstCue";
ax(i).trialType = ["leftCue_right", "rightCue_right"];
ax(i).window    = [-2, 2];
ax(i).color      = {colors.left,colors.right}; %Outcome: hit/priorHit vs err/priorHit
ax(i).lineStyle  = {'-','-'};
ax(i).xLabel = 'Time from first cue (s)';  % XLabel

i=i+1;
ax(i).title      = 'Last Cue';
ax(i).comparison    = "Last Cue";
ax(i).trigger   = "lastCue";
ax(i).trialType = ["leftCue_left", "rightCue_left"];
ax(i).window    = [-2, 2];
ax(i).color      = {colors.left,colors.right}; %Outcome: hit/priorHit vs err/priorHit
ax(i).lineStyle  = {'-','-'};
ax(i).xLabel = 'Time from last cue (s)';  % XLabel

i=i+1;
ax(i).title      = 'Last Cue';
ax(i).comparison    = "Last Cue";
ax(i).trigger   = "lastCue";
ax(i).trialType = ["leftCue_right", "rightCue_right"];
ax(i).window    = [-2, 2];
ax(i).color      = {colors.left,colors.right}; %Outcome: hit/priorHit vs err/priorHit
ax(i).lineStyle  = {'-','-'};
ax(i).xLabel = 'Time from last cue (s)';  % XLabel

[ax(:).yLabel]          = deal('Cellular Fluorescence (dF/F)');
[ax(:).verboseLegend]   = deal(false);