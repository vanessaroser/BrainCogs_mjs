function subjects_out = excludeWarmupPerformance( subjects, lastForcedChoiceLevel )
%%

fields.params = ["level","reward_scale","maxSkidAngle"];
fields.counts = ["nTrials","nCompleted","nForward"];
fields.mean = ["pCorrect","pCorrect_congruent","pCorrect_conflict","pOmit","pStuck"];
fields.max = ["maxCorrectMoving","maxCorrectMoving_congruent","maxCorrectMoving_conflict"];
fields.median = ["median_velocity","median_pSkid","median_stuckTime"];

for i = 1:numel(subjects)
    for j = 1:numel(subjects(i).sessions)
        S = subjects(i).sessions(j);
        
        %For L-Maze sessions
        if ismember(S.sessionType,["Sensory","Alternation"])
            blockIdx = S.level > lastForcedChoiceLevel;
        elseif S.sessionType=="Forced"
            blockIdx = S.level <= lastForcedChoiceLevel;
        else
            error('"sessionType" must be one of the following: "Forced", "Sensory", or "Alternation".')
        end
            
        %Filter session stats to exclude warmup blocks
            for F = [fields.params, fields.counts, fields.mean, fields.max, fields.median]
                S.(F) = S.(F)(blockIdx);
            end
            
            %No further processing for sessions with only one main block
            if sum(blockIdx)==1
                continue 
            end 
            
            %Session parameters
            for F = fields.params, S.(F) = S.(F)(end); end

            %Counts
            for F = fields.counts, S.(F) = sum(S.(F)); end

            %Max quantities
            for F = fields.max, S.(F) = max(S.(F)); end

            %Mean/proportional quantities
            weights = S.nCompleted ./ sum(S.nCompleted); %Weight sensory or alternation stats by the respective number of trials
            for F = ["pCorrect","pCorrect_congruent","pCorrect_conflict","pOmit","pStuck"]
                S.(F) = sum(S.(F) .* weights);
            end

            %Kinematic quantities (recalculate median values)
            trials = subjects(i).trials(j);
            trialData = subjects(i).trialData(j);
            fwdIdx = ismember(trials.blockIdx,find(blockIdx)) & trials.forward; %Filter completed sensory/alternation trials
            S.median_velocity = median(trialData.mean_velocity(fwdIdx,2)); %Median Y-velocity across all completed trials
            S.median_pSkid = median(trialData.pSkid(fwdIdx)); %Median proportion of maze where mouse skidded along walls
            S.median_stuckTime = median(trialData.stuck_time,'omitnan'); %Median proportion of time spent stuck as result of friction

            %Replace edited fields
            subjects(i).sessions(j) = S; 
    end
end