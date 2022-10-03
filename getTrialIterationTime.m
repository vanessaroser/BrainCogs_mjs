function t = getTrialIterationTime( log, blockIdx, trialIdx, iteration )

% ViRMEn timestamps for each iteration are relative to trial start time.
% Trial start time is relative to first block start time, unless session
% was restarted, in which case it is relative to the block start time
% following restart.

%Check for any restarts, where trial start time would be recorded as earlier than block start time.
currentBlockStartTime = seconds(datetime(log.block(blockIdx).start) - datetime(log.block(1).start));
firstTrialStartTime = log.block(blockIdx).trial(1).start;
referenceTime = 0;
if firstTrialStartTime < currentBlockStartTime
    %Find last restart
    for i = 1:blockIdx
        referenceTime = seconds(datetime(log.block(i).start) - datetime(log.block(1).start));
        correctedTrialStart  = referenceTime + firstTrialStartTime;
        if correctedTrialStart > currentBlockStartTime %Loop until block(i) start time + trial start time > current block start time
            break
        end
    end
end
trialStartTime = log.block(blockIdx).trial(trialIdx).start;
iterTime = log.block(blockIdx).trial(trialIdx).time(iteration); 

t = referenceTime + trialStartTime + iterTime;
