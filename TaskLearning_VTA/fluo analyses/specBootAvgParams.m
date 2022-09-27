function bootParams = specBootAvgParams( generalParams )

i = 1;
%Cue responses
bootParams(i).trigger = "cues";
bootParams(i).trialSpec = {...
    ["leftCue"],...
    ["rightCue"]};

i = i+1;
%Choice aligned to cueEntry
bootParams(i).trigger = "cueEntry";
bootParams(i).trialSpec = {...
    ["forward"],...
    ["left", "correct"],...
    ["right", "correct"]};

i = i+1;
%Choice aligned to turnEntry
bootParams(i).trigger = "turnEntry";
bootParams(i).trialSpec = {...
    ["forward"],...
    ["left", "correct"],...
    ["right", "correct"]};

i = i+1;
%Choice aligned to armEntry
bootParams(i).trigger = "armEntry";
bootParams(i).trialSpec = {...
    ["forward"],...
    ["left", "correct"],...
    ["right", "correct"]};

i = i+1;
%Choice aligned to y-position
bootParams(i).trigger = "cueRegion";
bootParams(i).trialSpec = {...
    ["forward"],...
    ["left"],...
    ["right"],...
    ["leftCue"],...
    ["rightCue"],...
    ["priorCorrect"],...
    ["priorError"],...
    ["correct","priorCorrect"],...
    ["correct","priorError"]};

i = i+1;
%Outcome aligned to outcome
bootParams(i).trigger = "outcome";
bootParams(i).trialSpec = {...
    ["correct","priorCorrect"],...
    ["correct","priorError"],...
    ["error","priorCorrect"],...
    ["error","priorError"],...
    ["left","correct"],...
    ["right","correct"],...
    ["correct","congruent"],...
    ["correct","conflict"],...
    ["error","congruent"],...
    ["error","conflict"]};

i = i+1;
%Left and right cues aligned to first cue onset
bootParams(i).trigger = "firstCue";
bootParams(i).trialSpec = {...
    ["leftCue","left"],...
    ["leftCue","right"],...
    ["rightCue","right"],...
    ["rightCue","left"]};

i = i+1;
%Left and right cues aligned to last cue onset
bootParams(i).trigger = "lastCue";
bootParams(i).trialSpec = {...
    ["leftCue","left"],...
    ["leftCue","right"],...
    ["rightCue","right"],...
    ["rightCue","left"],...
    ["leftCue","congruent"],...
    ["leftCue","conflict"],...
    ["rightCue","congruent"],...
    ["rightCue","conflict"]};

%Append general params
fields = fieldnames(generalParams);
for j = 1:numel(fields)
    [bootParams(1:i).(fields{j})] = deal(generalParams.(fields{j}));
end

