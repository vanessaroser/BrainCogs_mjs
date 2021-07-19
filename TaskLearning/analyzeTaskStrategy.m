function subjects = analyzeTaskStrategy(subjects)

for i = 1:numel(subjects)
    for j = 1:numel(subjects(i).sessions)
        
        % Trial masks for predictors and response variable
        trials = subjects(i).trials(j);
        rightCue = trials.rightCue(~trials.omit)';%Exclude omissions
        rightChoice = trials.right(~trials.omit)'; %Exclude omissions
        %Exclude first trial
        rightCue = rightCue(2:end);
        rightPriorChoice = rightChoice(1:end-1);
        rightChoice = rightChoice(2:end);
        
        %Additional masks for conflict trials
        conflict = trials.conflict(~trials.omit);
        correct = trials.correct(~trials.omit);
        pCorrect_conflict = mean(trials.correct(trials.conflict));
        pConflict = mean(conflict);
        
        %Logistic regression of Choices based on Sensory Cues and Prior Choice
        dummyCode = @(X) 2*(X-0.5);
        predictors = dummyCode([rightCue, rightPriorChoice]);
        response = rightChoice;
        if isempty(predictors) || isempty(response)
            [B, stats] = assignNaN();
        else
            lastwarn(''); % Clear last warning message
            [B,~,stats] = glmfit(predictors,response,'binomial','link','logit');
        end
        [warnMsg, warnId] = lastwarn;
        
        %Get condition number for GLM
        X = [ones(size(predictors,1),1),predictors]; %Design matrix
        moment = X'*X; %Moment matrix of regressors
        condNum = cond(moment); %Condition number
        
        %For ill-conditioned data
        if any([isempty(predictors),isempty(response)]) %any(isnan(stats.p)) %~exist('B') || 
            [B, stats] = assignNaN();
            predictors = NaN;
            response = NaN;
        end
   
        %Assign into output structures
        subjects(i).sessions(j).betaCues= B(2);
        subjects(i).sessions(j).betaChoice = B(3);
        subjects(i).sessions(j).bias = B(1);
        
        Stats = @(term) struct(...
            'beta',stats.beta(term),'se',stats.beta(term)+[-1,1]*stats.se(term),'p',stats.p(term));
        
        subjects(i).sessions(j).glm = struct(...
            'cueSide',Stats(2),'priorChoice',Stats(3),'bias',Stats(1),...
            'R_predictors',min(corrcoef(predictors),[],'all'),...
            'R_cue_choice',min(corrcoef([rightCue,response]),[],'all'),...
            'R_priorChoice_choice',min(corrcoef([rightPriorChoice,response]),[],'all'),...
            'N',numel(response),'pRightChoice',mean(rightPriorChoice),'pRightCue',mean(rightCue),...
            'conditionNum',condNum,...
            'warning',struct('msg',warnMsg,'ID',warnId));
        
          subjects(i).sessions(j).pConflict = pConflict;
          subjects(i).sessions(j).pCorrect_conflict = pCorrect_conflict;
        
        clearvars B stats
                
    end
end

function [B, stats] = assignNaN()
B = NaN(3,1);
stats = struct('beta',NaN(3,1),'se',NaN(3,1),'p',NaN(3,1));

% msg = arrayfun(@(sessionID) subjects(1).sessions(sessionID).glm.warning.msg,1:numel(subjects(1).sessions),'UniformOutput',false);