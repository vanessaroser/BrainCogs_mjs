%%% getTrialEventTimes(trials)
%
%PURPOSE: To extract the timing of key events in each trial of a ViRMEn maze-based task.
%
%AUTHOR: MJ Siniscalchi, Princeton Neuroscience Institute, 220415
%
%INPUT ARGUMENTS:
%   Structure array 'trials', containing fields:
%       'start', time at the start of each trial relative to ViRMEn startup
%       'position', an Nx3 matrix of virtual position in X, Y, and theta
%       'cuePos', a 1x2 cell array containing the y-position of left and right cues, respectively
%       'time', time of each iteration relative to startup 
%       'iterations', total number of iterations from start to outcome in each trial
%       'iCueEntry', the iteration corresponding to entry into the cue region
%       'iTurnEntry', the iteration corresponding to entry into the turn region
%       'iArmEntry', the iteration corresponding to entry into the arm region
%   Note: all fields logged in ViRMEn under the struct 'behavior.logs.block.trial'
%
%OUTPUTS:
%   Struct array 'eventTimes', of length equal to the number of trials and containing fields:
%       'start',
%       'cue'
%       'outcome'
%       'cueEntry'
%       'turnEntry'
%
%---------------------------------------------------------------------------------------------------

function eventTimes = getTrialEventTimes(trials)

eventTimes(numel(trials),1) = struct(...
    'start',[],'leftCues',[],'rightCues',[],'firstCue',[],'lastCue',[],'outcome',[],...
    'cueEntry',[],'turnEntry',[],'armEntry',[]); % Initialize

for i = 1:numel(trials)
    %Trial start times
    eventTimes(i).start =  trials(i).start;
    
    %Cue onset times
    yPos = trials(i).position(:,2); %Y-position of mouse in ViRMEn, one entry per iteration
    cueIter = arrayfun(@(P) find(yPos>P,1,"first"), [trials(i).cuePos{:}]); %First iteration after passing each cue
    cueTimes = trials(i).start + trials(i).time(cueIter)';

    %Left & right cue onsets
    eventTimes(i).leftCues = cueTimes(logical(trials(i).cueCombo(1,:)));
    eventTimes(i).rightCues = cueTimes(logical(trials(i).cueCombo(2,:)));

    %First & last cue onset
    eventTimes(i).firstCue = cueTimes(1);
    eventTimes(i).lastCue = cueTimes(end);
    
    %Outcome onset times
    eventTimes(i).outcome =  trials(i).start + trials(i).time(trials(i).iterations);
    
    %Time of entry into cue region, turn region (easeway before arm entry), and arm region
    fields = ["iCueEntry","iTurnEntry","iArmEntry"];
    for j = 1:numel(fields)
        eventTimes(i).([lower(fields{j}(2)) fields{j}(3:end)]) = []; %Initialize, eg 'eventTimes(i).turnEntry'
        if trials(i).(fields(j)) %If boundary crossed in current trial
            eventTimes(i).([lower(fields{j}(2)) fields{j}(3:end)]) = ...
                trials(i).start + trials(i).time(trials(i).(fields(j)));
        end
    end
end