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

function eventTimes = getTrialEventTimes(log, blockIdx)

trials = log.block(blockIdx).trial;
eventTimes(numel(trials),1) = struct(...
    'start',[],'cues',[],'firstCue',[],'lastCue',[],'outcome',[],...
    'cueEntry',[],'turnEntry',[],'armEntry',[]); % Initialize

for i = 1:numel(trials)
    %Trial start times
    eventTimes(i).start = getTrialIterationTime(log, blockIdx, i, 1); %Time of first iteration; needs correction in some cases because the reference time for trials(i).start changes after restarts, etc. 
     
    %Cue onset times
    if any([trials(i).cueOnset{:}]>1) %If cues appear during run (rather than at start or not at all)
        %Get iteration assoc with cue onset as time index
        cueTimes = sort(eventTimes(i).start... %Use eventTimes.start (corrected) rather than raw 'start' times
            + trials(i).time([trials(i).cueOnset{:}]))'; %trials(i).cueOnset sometimes = 0 (??)
        %     eventTimes(i).leftCues = cueTimes(logical(trials(i).cueCombo(1,:)));
        %     eventTimes(i).rightCues = cueTimes(logical(trials(i).cueCombo(2,:)));
        %Note: trials(i).cueCombo sorted in ViRMEn but not cuePos or cueOnset!
    else
        cueTimes = NaN;
    end
    eventTimes(i).cues      = cueTimes;
    eventTimes(i).firstCue  = cueTimes(1);
    eventTimes(i).lastCue   = cueTimes(end);

    %Outcome onset times
    eventTimes(i).outcome =  eventTimes(i).start + trials(i).time(trials(i).iterations); %Use eventTimes.start (corrected) rather than raw 'start' times
    
    %Time of entry into cue region, turn region (easeway before arm entry), and arm region
    fields = ["iCueEntry","iTurnEntry","iArmEntry"];
    for j = 1:numel(fields)
        eventTimes(i).([lower(fields{j}(2)) fields{j}(3:end)]) = NaN; %Initialize, eg 'eventTimes(i).turnEntry'
        if trials(i).(fields(j)) %If boundary crossed in current trial
            eventTimes(i).([lower(fields{j}(2)) fields{j}(3:end)]) = ...
                eventTimes(i).start + trials(i).time(trials(i).(fields(j))); %Use eventTimes.start (corrected) rather than raw 'start' times
        end
    end
end

% --- Notes -------

    %Alternative approach to Cue onset times, etc.
%     yPos = trials(i).position(:,2); %Y-position of mouse in ViRMEn, one entry per iteration
%     cueIter = arrayfun(@(P) find(yPos>P,1,"first"), [trials(i).cuePos{:}]); %First iteration after passing each cue position
%     cueTimes = sort(eventTimes(i).start + trials(i).time(cueIter))'; %trials(i).cueCombo sorted in ViRMEn but not cuePos! 
% **Remember to account for cueVisibleAt!**