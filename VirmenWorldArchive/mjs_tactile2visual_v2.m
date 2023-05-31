%%% mjs_memoryMaze()
%
% EXPERIMENT CODE for T-Maze with same name.
% AUTHOR: MJ Siniscalchi, 201224
% Edited from poisson_blocks.m
%-------------------------------------------

function code = mjs_taskLearningWalls

% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime        = @runtimeCodeFun;
code.termination    = @terminationCodeFun;
% End header code - DO NOT EDIT

code.setup          = @setupTrials;

end


%%_________________________________________________________________________
% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)

%Initialize frictionEngaged variable (needed at start to store frictionEngagedVector)
vr.frictionEngaged = 0;

% Initialize standard state control variables
vr    = initializeGradedExperiment(vr);

% Number and sequence of trials, reward level etc.
vr    = setupTrials(vr);

% Disable native session termination function
vr.enableAutoTerminateSession = false;

if RigParameters.hasDAQ
    % test motion detection
    vr  = checkSqual(vr);
end

% Standard communications lines for VR rig
vr    = initializeVRRig(vr, vr.exper.userdata.trainee);

%****** DEBUG DISPLAY ******
if ~RigParameters.hasDAQ && ~RigParameters.simulationMode
    vr.text(1).position     = [-1 0.7];
    vr.text(1).size         = 0.03;
    vr.text(1).color        = [1 1 0];
    vr.text(2).position     = [-1 0.65];
    vr.text(2).size         = 0.03;
    vr.text(2).color        = [1 1 0];
    vr.text(3).position     = [-1.6 0.9];
    vr.text(3).size         = 0.02;
    vr.text(3).color        = [1 1 0];
    vr.text(4).position     = [-1.6 0.85];
    vr.text(4).size         = 0.02;
    vr.text(4).color        = [1 1 0];
end
%***************************


end


%%_________________________________________________________________________
% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)
try

    %% Handle keyboard, remote input, wait times
    vr  = processKeypress(vr, vr.protocol);
    if vr.waitTime ~= 0
        [vr.waitStart, vr.waitTime] = processWaitTimes(vr.waitStart, vr.waitTime);
    end
    vr.prevState  = vr.state;


    %% Forced termination, or else do epoch-specific things
    if isinf(vr.protocol.endExperiment)
        vr.experimentEnded  = true;
    elseif vr.waitTime == 0   % Only if not in a time-out period...


        % --- Modifications of Towers Task for MJS Task Learning Experiment ------------------------
        vr = mjs_towersTaskMods(vr);

        %---------------------------------------------------------------------------------------------

        switch vr.state           % ... take action depending on the simulation state

            %========================================================================
            case BehavioralState.SetupTrial
                % Configure world for the trial; this is done separately from
                % StartOfTrial as it can take a long time and we want to teleport the
                % animal back to the start location only after this has been completed
                % and the Virmen engine can do whatever behind-the-scenes magic. If we
                % try to merge this step with StartOfTrial, animal motion can
                % accumulate during initialization and result in an artifact where the
                % animal is suddenly displaced forward upon start of world display.

                vr                    = initializeTrialWorld(vr);

                if vr.protocol.endExperiment == true
                    % Allow end of experiment only after completion of the last trial
                    vr.experimentEnded  = true;
                elseif ~vr.experimentEnded
                    vr.state            = BehavioralState.InitializeTrial;
                    vr                  = teleportToStart(vr);
                end


                %========================================================================
            case BehavioralState.InitializeTrial
                % Teleport to start and send signals indicating start of trial
                vr                    = teleportToStart(vr);
                vr                    = startVRTrial(vr);
                prevDuration          = vr.logger.logStart(vr);
                vr.protocol.recordTrialDuration(prevDuration);

                % Make the world visible
                vr.state              = BehavioralState.StartOfTrial;
                vr.worlds{vr.currentWorld}.surface.visible = vr.defaultVisibility;

                %========================================================================
            case BehavioralState.StartOfTrial
                % We keep the animal at the start of the track for the first iteration of the trial where
                % the world is actually visible. This is only as a safety factor in case the first rendering
                % (caching) of the world graphics makes the previous iteration take unusually long, in which
                % case displacement is accumulated without the animal actually responding to anything.
                vr.state              = BehavioralState.WithinTrial;
                vr                    = teleportToStart(vr);


                %========================================================================
            case BehavioralState.WithinTrial
                % Reset sound counter if no longer relevant
                if ~isempty(vr.soundStart) && toc(vr.soundStart) > vr.punishment.duration
                    vr.soundStart       = [];
                end

                %% Epoch-specific event handlers

                %------------------------------------------------------------------------
                % Check if animal has met the trial violation criteria
                if isViolationTrial(vr)
                    vr.choice           = Choice.nil;
                    vr.state            = BehavioralState.ChoiceMade;

                    %------------------------------------------------------------------------
                    % Check if animal has entered a choice region after it has entered an arm
                elseif vr.iArmEntry > 0
                    for iChoice = 1:numel(vr.cross_choice)
                        if isPastCrossing(vr.cross_choice(iChoice), vr.position)
                            vr.choice       = Choice(iChoice);
                            vr.state        = BehavioralState.ChoiceMade;
                            break;
                        end
                    end

                    %------------------------------------------------------------------------
                    % Check if animal has entered the T-maze arms after the turn region
                elseif vr.iTurnEntry > 0
                    if isPastCrossing(vr.cross_arms, vr.position)
                        vr.iArmEntry      = vr.iterFcn(vr.logger.iterationStamp(vr));
                    end

                    %------------------------------------------------------------------------
                    % Check if animal has entered the turn region after the memory period
                elseif vr.iMemEntry > 0
                    if isPastCrossing(vr.cross_turn, vr.position)
                        vr.iTurnEntry     = vr.iterFcn(vr.logger.iterationStamp(vr));
                    end

                    % Also test for entry in the arm in case there is no turn region
                    if isPastCrossing(vr.cross_arms, vr.position)
                        vr.iArmEntry      = vr.iterFcn(vr.logger.iterationStamp(vr));
                    end

                    %------------------------------------------------------------------------
                    % Check if animal has entered the memory region after the cue period
                elseif vr.iCueEntry > 0 && isPastCrossing(vr.cross_memory, vr.position)
                    vr.iMemEntry        = vr.iterFcn(vr.logger.iterationStamp(vr));
                    if isPastCrossing(vr.cross_turn, vr.position)
                        vr.iTurnEntry     = vr.iterFcn(vr.logger.iterationStamp(vr));
                    end

                    % Turn off visibility of cues in memory region (instead of time-based disappearance)
                    if isinf(vr.cueDuration)
                        vr.worlds{vr.currentWorld}.surface.visible = vr.defaultVisibility;
                    end

                    %------------------------------------------------------------------------
                    % If still in the start region, do nothing
                elseif vr.iCueEntry < 1 && ~isPastCrossing(vr.cross_cue, vr.position)

                    % If in the cue region, make cues visible when the animal is close enough
                else
                    if vr.iCueEntry < 1
                        vr.iCueEntry      = vr.iterFcn(vr.logger.iterationStamp(vr));
                    end

                    % Cues are triggered only when animal is facing forward
                    if abs(angleMPiPi(vr.position(end))) < pi/2

                        %% Loop through cues on both sides of the maze
                        for iSide = 1:numel(ChoiceExperimentStats.CHOICES)
                            %% If the cue is not on, check if we should turn it on
                            cueDistance     = vr.cuePos{iSide} - vr.position(2);
                            isTriggered     = ~vr.cueAppeared{iSide}              ...
                                & (cueDistance <= vr.cueVisibleAt)    ...
                                ;
                            if ~any(isTriggered)
                                continue;
                            end

                            %% If approaching a cue and near enough, make it visible in the next iteration
                            triangles     = vr.tri_turnCue(iSide,:,isTriggered);
                            vr.cueAppeared{iSide}(isTriggered)  = true;
                            vr.cueOnset{iSide}(isTriggered)     = vr.logger.iterationStamp(vr);
                            vr.cueTime{iSide}(isTriggered)      = vr.timeElapsed;
                            if ~(vr.cueDuration < 0)            %% negative durations (but not NaNs) make cues invisible
                                vr.worlds{vr.currentWorld}.surface.visible(triangles) = true;
                            end
                        end
                    end
                end


                %% Time-based visibility controls

                %------------------------------------------------------------------------
                % If a cue is already on, turn it off if enough time has elapsed
                for iSide = 1:numel(ChoiceExperimentStats.CHOICES)
                    isTurnedOff         = ( vr.timeElapsed - vr.cueTime{iSide} >= vr.cueDuration );
                    if any(isTurnedOff)
                        triangles         = vr.tri_turnCue(iSide,:,isTurnedOff);
                        vr.cueTime{iSide}(isTurnedOff)    = nan;
                        vr.cueOffset{iSide}(isTurnedOff)  = vr.logger.iterationStamp(vr);
                        vr.worlds{vr.currentWorld}.surface.visible(triangles) = false;
                    end
                end

                %========================================================================
            case BehavioralState.ChoiceMade
                % Log the end of the trial
                vr.excessTravel = vr.logger.distanceTraveled() / vr.mazeLength - 1;
                vr.logger.logEnd(vr);

                % Freeze movement
                vr = freezeArduino(vr);

                % Detemine trial outcome
                if vr.choice == vr.trialType
                    vr.state        = BehavioralState.DuringReward; %Update state
                    vr.rewardFactor = vr.protocol.rewardScale; %Record reward for delivery in "DuringReward" state next iteration
                else
                    vr.negOutcomeSound.play; %For error or miss trial
                    vr.state        = BehavioralState.EndOfTrial;
                    vr.rewardFactor = 0;
                    vr.waitTime     = vr.trialEndPauseDur;
                end

                % Update movement data display
                rawVel    = double(vr.logger.currentTrial.sensorDots(1:size(vr.logger.currentTrial.position,1), [4 3]));
                vr.protocol.updateRun ( vr.logger.currentTrial.position       ...
                    , vr.logger.currentTrial.velocity       ...
                    , atan2(-rawVel(:,1).*sign(rawVel(:,2)), abs(rawVel(:,2)))   ... HACK: bottom sensor specific!
                    );


                %========================================================================
            case BehavioralState.DuringReward
                % This intermediate state is necessary so that whatever changes to the
                % ViRMen world upon rewarded behavior is applied before entering the
                % end of trial wait period
                vr = rewardVRTrial(vr, vr.rewardFactor);

                % For human testing, flash the screen green if correct and red if wrong
                if ~RigParameters.hasDAQ && ~RigParameters.simulationMode
                    if vr.choice == vr.trialType
                        vr.worlds{vr.currentWorld}.backgroundColor  = [0 1 0] * 0.8;
                    elseif vr.choice == vr.wrongChoice
                        vr.worlds{vr.currentWorld}.backgroundColor  = [1 0 0] * 0.8;
                    else
                        vr.worlds{vr.currentWorld}.backgroundColor  = [0 0.5 1] * 0.8;
                    end
                end


                %========================================================================
            case BehavioralState.EndOfTrial
                %Delay trial end until all outcome events (reward consumption, sounds, etc.) are complete
                if isfield(vr,'delayEndOfTrial') && vr.delayEndOfTrial
                    vr.state = BehavioralState.EndOfTrial; %Maintain state until delay is lifted
                else
                    % Send signals indicating end of trial and start inter-trial interval
                    vr          = endVRTrial(vr);
                    vr.iBlank   = vr.iterFcn(vr.logger.iterationStamp(vr));
                end

                %========================================================================
            case BehavioralState.InterTrial
                % Handle input of comments etc.
                vr.logger.logExtras(vr, vr.rewardFactor);
                vr.state    = BehavioralState.SetupTrial;
                if ~RigParameters.hasDAQ
                    vr.worlds{vr.currentWorld}.backgroundColor  = [0 0 0];
                end

                % Record performance for the trial
                vr.protocol.recordChoice( vr.choice                                   ...
                    , vr.rewardFactor * RigParameters.rewardSize  ...
                    , vr.trialWeight                              ...
                    , vr.excessTravel < vr.maxExcessTravel        ...
                    , vr.logger.trialLength()                     ...
                    , cellfun(@numel, vr.cuePos)                  ...
                    );

                % Decide duration of inter trial interval
                if vr.choice == vr.trialType
                    vr.waitTime       = vr.itiCorrectDur;
                else
                    vr.waitTime       = vr.itiWrongDur;
                end



                %========================================================================
            case BehavioralState.EndOfExperiment
                vr.experimentEnded  = true;

        end
    end                     % Only if not in time-out period


    %% Apply motion blurring to cues
    dy                      = vr.lastDP(2) + vr.dp(2);
    vr.lastDP               = vr.dp;
    if ~isempty(vr.motionBlurRange)
        % Quantities for motion blurring
        blurredWidth          = vr.yCue + abs(dy);

        % Only visible cues within a given distance of the animal are blurred
        isBlurred             = false(size(vr.vtx_turnCue));
        if abs(dy) > vr.motionBlurRange(1)
            for iSide = 1:numel(vr.cuePos)
                isBlurred(iSide, :, vr.cueAppeared{iSide}                                           ...
                    & abs(vr.cuePos{iSide} - vr.position(2)) < vr.motionBlurRange(2)  ...
                    ) = true;
            end
        else
            isBlurred(:)        = false;
        end
        isReset               = vr.cueBlurred & ~isBlurred;
        vr.cueBlurred         = isBlurred;

        % Reset cues that are no longer blurred
        vertices            = vr.vtx_turnCue(isReset);
        if ~isempty(vertices)
            vtxOffset         = vr.template_turnCue(isReset) * vr.yCue;
            vr.worlds{vr.currentWorld}.surface.vertices(2,vertices)     ...
                = vr.pos_turnCue(isReset) + vtxOffset;
            if ~isnan(vr.dimCue)
                vr.worlds{vr.currentWorld}.surface.colors(:,vertices)     ...
                    = vr.color_turnCue(:,1:numel(vertices));
            end
        end

        % Elongate cues opposite to direction of motion
        vertices            = vr.vtx_turnCue(isBlurred);
        if ~isempty(vertices)
            vtxOffset         = dy/2 + vr.template_turnCue(isBlurred) * blurredWidth;
            vr.worlds{vr.currentWorld}.surface.vertices(2,vertices)     ...
                = vr.pos_turnCue(isBlurred) + vtxOffset;

            % Impose a falloff gradient if so desired
            if ~isnan(vr.dimCue)
                if abs(angleMPiPi(vr.position(end))) < pi/2
                    vtxOffset     = vr.template_turnCue(isBlurred);
                else
                    vtxOffset     = -vr.template_turnCue(isBlurred);
                end
                edgeLoc         = vr.yCue / blurredWidth - 0.5;
                isDimmed        = ( vtxOffset > edgeLoc );

                vtxOffset       = vtxOffset(isDimmed);
                vtxColor        = vr.cueColor                   ...
                    + (vr.dimCue - vr.cueColor)     ...
                    * (vtxOffset - edgeLoc)         ...
                    / (0.5       - edgeLoc)         ...
                    ;

                vr.worlds{vr.currentWorld}.surface.colors(:,vertices(isDimmed))   ...
                    = bsxfun(@times, vtxColor', RigParameters.colorAdjustment);
            end
        end
    end


    %% IMPORTANT: Log position, velocity etc. at *every* iteration
    loggingIndices        = vr.logger.logTick(vr, vr.sensorData);
    vr.protocol.update();

    % Send DAQ signals for multi-computer synchronization
    updateDAQSyncSignals(vr.iterFcn(loggingIndices));

catch err
    displayException(err);
    vr.experimentEnded    = true;
    rethrow(err);
end
end

%%_________________________________________________________________________
% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)

% Stop user control via statistics display
vr.protocol.stop();

% Log various pieces of information
if isfield(vr, 'logger') && ~isempty(vr.logger.logFile)
    % Save via logger first to discard empty records
    log = vr.logger.save(true, vr.timeElapsed, vr.protocol.getPlots());

    vr.exper.userdata.regiment.recordBehavior(vr.exper.userdata.trainee, log, vr.logger.newBlocks);
    vr.exper.userdata.regiment.save();
end

% Standard communications shutdown
terminateVRRig(vr);

% write to google database
try writeTrainingDataToDatabase(log,vr); catch; warning('Problem writing to database, please check spreadsheet'); end

end


%%_________________________________________________________________________
% --- (Re-)triangulate world and obtain various subsets of interest
function vr = computeWorld(vr)

% Modify the ViRMen world to the specifications of the given maze; sets
% vr.mazeID to the given mazeID
[vr,lCue,stimParameters]  = configureMaze(vr, vr.mazeID, vr.mainMazeID);
vr.mazeLength             = vr.lStart                                   ...
    - vr.worlds{vr.currentWorld}.startLocation(2) ...
    + vr.lCue                                     ...
    + vr.lMemory                                  ...
    + vr.lArm                                     ...
    ;
vr.stemLength             = vr.lCue                                     ...
    + vr.lMemory                                  ...
    ;

% Specify parameters for computation of performance statistics
% (maze specific for advancement criteria)
criteria                  = vr.mazes(vr.mainMazeID).criteria;
if vr.warmupIndex > 0
    vr.protocol.setupStatistics(criteria.warmupNTrials(vr.warmupIndex), 1, false);
else
    if isnan(criteria.easyBlock)
        vr.protocol.setupStatistics(criteria.numTrials, 1, false);
    else
        vr.protocol.setupStatistics(criteria.numBlockTrials, 1, false);
    end
end


% Mouse is considered to have made a choice if it enters one of these areas
vr.cross_choice           = getCrossingLine(vr, {'choiceLFloor', 'choiceRFloor'}, 1, @minabs);

%% Other regions of interest in the maze
vr.cross_cue              = getCrossingLine(vr, {'cueFloor'}   , 2, @min);
vr.cross_memory           = getCrossingLine(vr, {'memoryFloor'}, 2, @min);
vr.cross_turn             = getCrossingLine(vr, {'turnFloor'}  , 2, @min);
vr.cross_arms             = getCrossingLine(vr, {'armsFloor'}  , 2, @min);

%% Indices of left/right turn cues
turnCues                  = {'leftTurnCues', 'rightTurnCues'};
vr.tri_turnCue            = getVirmenFeatures('triangles', vr, turnCues);
vr.vtx_turnCue            = getVirmenFeatures('vertices' , vr, turnCues);

% HACK to deduce which triangles belong to which tower -- they seem to be
% ordered by column from empirical tests
vr.tri_turnCue            = reshape(vr.tri_turnCue, size(vr.tri_turnCue,1), [], vr.nCueSlots);
vr.vtx_turnCue            = reshape(vr.vtx_turnCue, size(vr.vtx_turnCue,1), [], vr.nCueSlots);
vr.cueBlurred             = false(size(vr.vtx_turnCue));


% Cache various properties of the loaded world (maze configuration) for speed
vr                        = cacheMazeConfig(vr);
vr.cueIndex               = zeros(1, numel(turnCues));
vr.slotPos                = nan(numel(ChoiceExperimentStats.CHOICES), vr.nCueSlots);
for iChoice = 1:numel(turnCues)
    vr.cueIndex(iChoice)    = vr.worlds{vr.currentWorld}.objects.indices.(turnCues{iChoice});
    cueObject               = vr.exper.worlds{vr.currentWorld}.objects{vr.cueIndex(iChoice)};
    vr.slotPos(iChoice,:)   = cueObject.y;
end

% Set and record template position of cues
vr.template_turnCue       = nan(size(vr.vtx_turnCue));
for iSide = 1:numel(turnCues)
    cueIndex                = vr.worlds{vr.currentWorld}.objects.indices.(turnCues{iSide});
    vertices                = vr.vtx_turnCue(iSide, :, :);
    vtxLoc                  = vr.worlds{vr.currentWorld}.surface.vertices(2,vertices);
    vtxLoc                  = reshape(vtxLoc, size(vertices));
    cueLoc                  = vr.exper.worlds{vr.currentWorld}.objects{cueIndex}.y;
    if ~isempty(vr.motionBlurRange)
        cueWidth              = vr.exper.worlds{vr.currentWorld}.objects{cueIndex}.height;
    else
        cueWidth              = 1;
    end

    vr.template_turnCue(iSide,:,:)  ...
        = bsxfun(@minus, vtxLoc, shiftdim(cueLoc,-1)) / cueWidth;
end

% Set and record template color of cues
if ~isempty(vr.motionBlurRange) && ~isnan(vr.dimCue)
    vr.color_turnCue        = vr.cueColor                               ...
        * repmat( RigParameters.colorAdjustment     ...
        , 1, numel(vr.vtx_turnCue)          ...
        )                                   ...
        ;
end

%% Set up Poisson stimulus train
[modified, vr.stimulusConfig] = vr.poissonStimuli.configure(lCue, stimParameters{:});
if modified
    errordlg( sprintf('Stimuli parameters had to be configured for maze %d.', vr.mazeID)  ...
        , 'Stimulus sequences not configured', 'modal'                       ...
        );
    vr.experimentEnded      = true;
    return;
end

end


%%_________________________________________________________________________
% --- Modify the world for the next trial
function vr = initializeTrialWorld(vr)

% Recompute world for the desired maze level if necessary
[vr, mazeChanged]         = decideMazeAdvancement(vr, vr.numMazesInProtocol);
if vr.experimentEnded; return; end

if mazeChanged
    vr                      = computeWorld(vr);

    % The recomputed world should remain invisible until after the ITI
    vr.worlds{vr.currentWorld}.surface.visible(:) = false;
end

% Adjust the reward level and trial drawing method
if mazeChanged
    if vr.updateReward % flag to update reward, won't do it during easy block
        vr.protocol.updateRewardScale(vr.warmupIndex, vr.mazeID);
    end
    if vr.warmupIndex > 0
        trialDrawMethod       = vr.exper.userdata.trainee.warmupDrawMethod;
    else
        trialDrawMethod       = vr.exper.userdata.trainee.mainDrawMethod;
    end
    vr.protocol.setDrawMethod(TrainingRegiment.(trialDrawMethod{1}){trialDrawMethod{2}});
end


% Select a trial type, i.e. whether the correct choice is left or right
[success, vr.trialProb]   = vr.protocol.drawTrial(vr.mazeID, [-vr.lStart, vr.lCue + vr.lMemory + 40]);
if isempty(vr.forcedIndex)
    vr.experimentEnded      = ~success;
    vr.trialType            = Choice(vr.protocol);
else
    vr.trialProb            = nan;
    vr.trialType            = vr.forcedTypes(vr.forcedIndex);
    vr.forcedIndex          = mod(vr.forcedIndex, numel(vr.forcedTrials)) + 1;
end
vr.wrongChoice            = setdiff(ChoiceExperimentStats.CHOICES, vr.trialType);

% Flags for animal's progress through the maze
vr.iCueEntry              = vr.iterFcn(0);
vr.iMemEntry              = vr.iterFcn(0);
vr.iTurnEntry             = vr.iterFcn(0);
vr.iArmEntry              = vr.iterFcn(0);
vr.iBlank                 = vr.iterFcn(0);

% Assign cues to rewarded and unrewarded sides
[vr, vr.trialWeight]      = drawCueSequence(vr);

%Configure Default Visibility of Tower Cues
vr.defaultVisibility  = vr.visibilityMask; %Line from configureCues(); 'visibilityMask' from vr = cacheMazeConfig(vr, forceVisibility)
triangles = vr.tri_turnCue(:); %Indices of tower cues into vr.visibilityMask

%Permanent cues visible from start
if ~isfinite(vr.cueVisibleAt)
    vr.defaultVisibility(triangles) = true;
    if isfield(vr, 'cueAppeared')
        for iSide = 1:numel(vr.cuePos)
            vr.cueAppeared{iSide}(:)  = true;
            vr.cueOnset{iSide}(:)     = 1;
            vr.cueTime{iSide}(:)      = 0;
        end
    end
end %end ~isfinite(vr.cueVisibleAt)

%Hide cues by default if specified
if isinf(vr.cueDuration) ||...  %cueDuration = inf makes towers invisible in memory region
        vr.cueDuration < 0     %negative cueDuration makes towers invisible
    vr.defaultVisibility(triangles) = false;
end

end %end function

%%_________________________________________________________________________
% --- Draw a random cue sequence ---
% Re-written for Multisensory Rule-Switching Task, MJS 230327  
function [vr, nonTrivial] = drawCueSequence(vr)

% Common storage
% Visual (tower) cues
vr.cuePos                 = cell(size(ChoiceExperimentStats.CHOICES));
vr.cueOnset               = cell(size(ChoiceExperimentStats.CHOICES));
vr.cueOffset              = cell(size(ChoiceExperimentStats.CHOICES));
vr.cueTime                = cell(size(ChoiceExperimentStats.CHOICES));    % Redundant w.r.t. cueOnset, but useful for checking duration
vr.cueAppeared            = cell(size(ChoiceExperimentStats.CHOICES));

% Tactile cues: air-puffs
vr.lastPuffTime           = tic; %Reset
vr.puffPos                = cell(size(ChoiceExperimentStats.CHOICES));
vr.puffOnset              = cell(size(ChoiceExperimentStats.CHOICES));
vr.puffAppeared           = cell(size(ChoiceExperimentStats.CHOICES));

% Draw the next trial in the configured sequence
trial                   = vr.poissonStimuli.nextTrial();
if isempty(trial)
    vr.experimentEnded      = true;
    nonTrivial              = false;
    return;
end
vr.cueCombo     = trial.cueCombo; %Leave cueCombo to represent [salient; distractor] combination for each trial; different from ATT, where it is converted to [left; right]
vr.nSalient     = trial.nSalient;
vr.nDistract    = trial.nDistract;
vr.trialID      = trial.index;

% Convert salient/distractor stimuli to relevant sensory modality
[goalSide, distractorSide] = deal(false(1,2)); %
goalSide(int8(vr.trialType)) = true; %Relevant modality on rewarded side
distractorSide(randi(2)) = true; %Randomize side for the distractor modality
if vr.tactileRule
    vr.cuePos(distractorSide) = trial.cuePos(2); %Only Distractors visible; [salient; distractor]
    vr.puffPos(goalSide)      = trial.cuePos(1); %Salient stimulus: air-puffs
elseif vr.visualRule
    vr.cuePos(goalSide)         = trial.cuePos(1); %Salient feature visible: tower cues
    vr.puffPos(distractorSide)  = trial.cuePos(2); %Distractors invisible (air-puffs)
elseif vr.forcedChoice %**Might default to cell(1,2); if so, then get rid of next two lines...
    vr.cuePos         = cell(1,2); %Salient feature visible: tower cues
    vr.puffPos        = cell(1,2); %Distractors invisible (air-puffs)
end

% Initialize times at which cues were turned on
cueDisplacement           = zeros(numel(vr.cuePos), 1, vr.nCueSlots);
for iSide = 1:numel(vr.cuePos)
    cueDisplacement(iSide,:,1:numel(vr.cuePos{iSide}))  = vr.cuePos{iSide};
    %Visual
    vr.cueOnset{iSide}      = zeros(size(vr.cuePos{iSide}), vr.iterStr);
    vr.cueOffset{iSide}     = zeros(size(vr.cuePos{iSide}), vr.iterStr);
    vr.cueTime{iSide}       = nan(size(vr.cuePos{iSide}));
    vr.cueAppeared{iSide}   = false(size(vr.cuePos{iSide}));
    %Tactile
    vr.puffOnset{iSide}     = zeros(size(vr.puffPos{iSide}), vr.iterStr);
    vr.puffAppeared{iSide}  = false(size(vr.puffPos{iSide}));
end

% Reposition cues according to the drawn positions
vr.pos_turnCue            = repmat(cueDisplacement, 1, size(vr.vtx_turnCue,2), 1);
vr.worlds{vr.currentWorld}.surface.vertices(2,vr.vtx_turnCue) ...
    = vr.template_turnCue(:) + vr.pos_turnCue(:);

% Only count trials with nontrivial cue distributions for performance display
nonTrivial                = isinf(vr.cueProbability) || (vr.nDistract >  0);
end

%%_________________________________________________________________________
% --- Trial and reward configuration
function vr = setupTrials(vr, shaping)

% Sequence of progressively more difficult mazes; see docs for prepareMazes()
if nargin < 2
    shaping             = vr.exper.userdata.trainee.protocol;
end
[mazes, criteria, globalSettings, vr]   ...
    = shaping(vr);
vr                    = prepareMazes(vr, mazes, criteria, globalSettings);
vr.shapingProtocol    = shaping;

% Precompute maximum number of cue towers given the cue region length and
% minimum tower separation
cueMinSeparation      = str2double(vr.exper.variables.cueMinSeparation);
for iMaze = 1:numel(vr.mazes)
    vr.mazes(iMaze).variable.nCueSlots  = num2str(floor( str2double(vr.mazes(iMaze).variable.lCue)/cueMinSeparation ));
end

% Number and mixing of trials
vr.targetNumTrials    = eval(vr.exper.variables.targetNumTrials);
vr.fracDuplicated     = eval(vr.exper.variables.fracDuplicated);
vr.trialDuplication   = eval(vr.exper.variables.trialDuplication);
vr.trialDispersion    = eval(vr.exper.variables.trialDispersion);
vr.panSessionTrials   = eval(vr.exper.variables.panSessionTrials);
vr.trialType          = Choice.nil;
vr.lastDP             = [0 0 0 0];

% Nominal extents of world
vr.worldXRange        = eval(vr.exper.variables.worldXRange);
vr.worldYRange        = eval(vr.exper.variables.worldYRange);

% Trial violation criteria
vr.maxTrialDuration   = eval(vr.exper.variables.maxTrialDuration);
[vr.iterFcn,vr.iterStr] = smallestUIntStorage(vr.maxTrialDuration / RigParameters.minIterationDT);

% Special case with no animal -- only purpose is to return maze configuration
hasTrainee            = isfield(vr.exper.userdata, 'trainee');


%--------------------------------------------------------------------------

% Auditory feedback for non-reward trials
Fs = 15000;
noiseDuration = 0.2; %in seconds
pauseDuration = 0.1; %in seconds
noise = [...
    randn(round(noiseDuration*Fs),1);...    %Gaussian noise
    zeros(round(pauseDuration*Fs),1);...    %Pause
    randn(round(noiseDuration*Fs),1)];      %Gaussian noise
vr.negOutcomeSound = audioplayer([noise, noise], Fs); %Noise on both channels

% Logged variables
if hasTrainee
    vr.sensorMode       = vr.exper.userdata.trainee.virmenSensor;
    %vr.frictionCoeff    = vr.exper.userdata.trainee.virmenFrictionCoeff;
end

% variables for easy blocks, auto rewards etc
vr.easyBlockFlag      = false;
vr.updateReward       = true;
vr.rewardAutoUpdated  = false;
vr.numRewardDrops     = 1;


% Configuration for logging etc.
cfg.label             = vr.exper.worlds{1}.name(1);
cfg.versionInfo       = { 'mazeVersion', 'codeVersion' };
cfg.mazeData          = { 'mazes' };
cfg.trialData         = { 'trialProb', 'trialType', 'choice', 'trialID'         ...
    , 'cueCombo', 'cuePos', 'cueOnset', 'cueOffset','puffPos','puffOnset'       ...
    ,'forcedChoice', 'visualRule', 'tactileRule'                                                         ...
    , 'iCueEntry', 'iMemEntry', 'iTurnEntry', 'iArmEntry', 'iBlank'             ...
    , 'excessTravel'                                                            ...
    };
cfg.protocolData      = { 'rewardScale' };
cfg.blockData         = { 'mazeID', 'mainMazeID', 'motionBlurRange', 'iterStr', 'shapingProtocol'             ...
    , 'frozenStimuli', 'stimulusBank', 'stimulusCommit', 'stimulusConfig', 'stimulusSet'  ...
    , 'easyBlockFlag'                                                                     ...
    };
cfg.totalTrials       = vr.targetNumTrials + vr.panSessionTrials;
cfg.savePerNTrials    = 1;
cfg.pollInterval      = eval(vr.exper.variables.logInterval);
cfg.repositoryLog     = '..\..\version.txt';

if hasTrainee
    cfg.animal          = vr.exper.userdata.trainee;
    cfg.logFile         = vr.exper.userdata.regiment.whichLog(vr.exper.userdata.trainee);
    cfg.sessionIndex    = vr.exper.userdata.trainee.sessionIndex;
end

% The following variables are refreshed (assigned under the vr struct) each time a different maze level is loaded
vr.experimentVars     = unique([...
    vr.stimulusParameters,... % vr.stimulusParameters is set in the protocol and includes e.g. cueVisibleAt
    fieldnames(vr.mazes(1).variable)',... %Maze variables set in the protocol
    {'yCue','lArm','maxExcessTravel'}]); %Extra vars required by runtime function

if ~hasTrainee
    return;
end

% Statistics for types of trials and success counts
vr.protocol           = ChoiceExperimentStats(cfg.animal, cfg.label, cfg.totalTrials, numel(mazes));
vr.protocol.plot(1 + ~RigParameters.hasDAQ);
vr.protocol.addDrawMethod(TrainingRegiment.TRIAL_DRAWING);

vr.protocol.log('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
vr.protocol.log('    %s : %s, session %d', vr.exper.userdata.trainee.name, datestr(now), vr.exper.userdata.trainee.sessionIndex);
vr.protocol.log('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');

% Predetermine warmup and main mazes based on training history
[vr.mainMazeID, vr.mazeID, vr.warmupIndex, vr.prevPerformance]  ...
    = getTrainingLevel(vr.mazes, vr.exper.userdata.trainee, vr.protocol, vr.numMazesInProtocol, cfg.animal.autoAdvance);
vr.motionBlurRange    = vr.exper.userdata.trainee.motionBlurRange;
vr.iMemEntry          = vr.iterFcn(0);
vr.iTurnEntry         = vr.iterFcn(0);
if ~isempty(vr.motionBlurRange)
    vr.experimentVars   = [vr.experimentVars, {'cueColor', 'dimCue'}];
end

% Protocol-specific stimulus trains, some identical across sessions
if ~isfinite(vr.exper.userdata.trainee.stimulusSet)
    vr.exper.userdata.trainee.stimulusBank  = '';
    vr.exper.userdata.trainee.stimulusSet   = 1;
end
if isempty(vr.exper.userdata.trainee.stimulusBank)
    vr.frozenStimuli    = false;
    if ~isfield(vr, 'defaultStimulusSet')
        vr.defaultStimulusSet = func2str(shaping);
    end
    vr.stimulusBank     = fullfile( parsePath(getfield(functions(shaping), 'file'))     ...
        , ['stimulus_trains_' vr.defaultStimulusSet '.mat']   ...
        );
    vr                  = checkStimulusBank(vr, false);

    % Load custom stimulus bank if provided
else
    vr.frozenStimuli    = true;
    vr.stimulusBank     = vr.exper.userdata.trainee.stimulusBank;
    vr                  = checkStimulusBank(vr, true);
end

% Logging of experimental data
if ~vr.experimentEnded
    vr.logger           = ExperimentLog(vr, cfg, vr.protocol, vr.iterFcn(inf));
end
vr.prevIndices = [0 0 0];

end
