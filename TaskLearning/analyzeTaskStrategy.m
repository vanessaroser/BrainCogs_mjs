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
        
        %Logistic regression of Choices based on Sensory Cues and Prior Choice
        predictors = [rightCue,rightPriorChoice];
        response = rightChoice;
        if isempty(predictors) || isempty(response)
            [B, stats] = assignNaN();
        else
            [B,~,stats] = glmfit(predictors,response,'binomial','link','logit');
        end
        
        %For ill-conditioned data
        if ~exist('B') || any(isnan(stats.p))
            [B, stats] = assignNaN();
        end
        
        %Make Beta(p<0.05) NaN
        B(stats.p>=0.05) = NaN;
        
        %Assign into output structures
        subjects(i).sessions(j).betaCues= B(2);
        subjects(i).sessions(j).betaChoice = B(3);
        subjects(i).sessions(j).bias = B(1);
        
        Stats = @(term) struct('beta',stats.beta(term),'se',stats.beta(term)+[-1,1]*stats.se(term),'p',stats.p(term));
        subjects(i).sessions(j).glm = struct('cueSide',Stats(2),'priorChoice',Stats(3),'bias',Stats(1));
        
        clearvars B stats
    end
end

function [B, stats] = assignNaN()
B = NaN(3,1);
stats = struct('beta',NaN(3,1),'se',NaN(3,1),'p',NaN(3,1));