function behavior = restrictImgTrials( behavior, mainMazeIdx )

behavior.trials.exclude(behavior.trials.level~=mainMazeIdx) = true; %'exclude' field used in getMasks()

level = unique(behavior.trials.level(behavior.trials.level~=mainMazeIdx));
warning(['Excluding ' num2str(sum(behavior.trials.level~=mainMazeIdx)) ' events from level ' num2str(level) '. Check!'])
