function [mazes, criteria, globalSettings, vr] = MJS_MemoryMaze_unconditionalLove(vr)

  %_______________________________________ 1 _____ 2 _____ 3 _____ 4 _____ 5 _____ 6 ____
  mazes     = struct( 'lStart'          , {2     , 10    , 10    , 10    , 10    , 10   }   ... final length 300 before turn
                    , 'lCue'            , {15    , 35    , 100   , 100   , 100   , 100  }   ...
                    , 'lMemory'         , {3     , 40    , 50    , 200   , 200   , 200  }   ...
                    , 'tri_turnHint'    , {false , false , false , false , true  , true }   ...
                    , 'turnHint_Mem'    , {false , false , false , false , false , true }   ... turn off visual guide during memory segment                 
                    , 'cueDuration'     , {nan   , nan   , nan   , nan   , nan   , inf  }   ... seconds
                    , 'cueVisibleAt'    , {10    , 10    , 10    , 10    , 10    , 10   }   ...
                    , 'cueProbability'  , {0     , 0     , 0     , 0     , 0     , 0    }   ...
                    , 'cueDensityPerM'  , {0     , 0     , 0     , 0     , 0     , 0    }   ...
                    , 'antiFraction'    , {0     , 0     , 0     , 0     , 0     , 0    }   ... fraction of trials with inverted reward condition
                    , 'isShaping'       , {true  , true  , true  , true  , false , false}   ...
                    , 'meanChoiceReps'  , {3     , 3     , 3     , 3     , 3    , 3   }   ... Mean number of stay trials before reward removed from that side
                    , 'world'           , {1     , 1     , 1     , 1     , 1     , 1    }   ... index in vr.worlds
                    );
  criteria  = struct( 'numTrials'       , {5     , 5     , 5     , 5     , 5     , 5   }   ... Minimum number of trials the mouse must spend above performance 
                    , 'numTrialsPerMin' , {2     , 2     , 2     , 2     , 2     , 2   }   ... Number of trials required per minute to be considered maintaining “good” performance 
                    , 'criteriaNTrials' , {5     , 5     , 5     , 5     , 5     , 5   }     ... Number of trials in the running window used to measure performance for deciding whether to advance to the next maze
                    , 'warmupNTrials'   , {[]    , []    , []    , []    , []    , []   }   ...
                    , 'numSessions'     , {0     , 0     , 0     , 0     , 0     , 1000 }   ... Minimum number of sessions the navigator must have above criteria before advancing
                    , 'performance'     , {0.2   , 0.2   , 0.2   , 0.2   , 0.2   , 0.8  }   ... Minimum performance criterion to advance maze
                    , 'maxBias'         , {0.5   , 0.5   , 0.5   , 0.5   , 0.5   , 0.0  }   ... Max allowed side bias to advance
                    , 'warmupMaze'      , {[]    , []    , []    , []    , []     , []    }   ... Index of Virmen world in vr.worlds for the warmup maze for that particular main maze, which occurs at the start of a given session
                    , 'warmupPerform'   , {[]    , []    , []    , []    , []   , []  }   ... Minimum performance during warmup to advance to mainMaze
                    , 'warmupBias'      , {[]    , []    , []    , []    , []    , []   }   ... Max allowed side bias allowed during warmup to advance to main maze
                    , 'warmupMotor'     , {[]    , []    , []    , []    , []    , []   }   ... ??
                    , 'easyBlock'       , {nan   , nan   , nan   , nan   , nan   , nan  }   ... maze ID of easy block    
                    , 'easyBlockNTrials', {[]    , []    , []    , []    , []    , []   }   ... number of trials in easy block   
                    , 'numBlockTrials'  , {[]    , []    , []    , []    , []    , []   }   ... number of trials for sliding window performance
                    , 'blockPerform'    , {[]    , []    , []    , []    , []    , []   }   ... performance threshold to go into easy block
                    );

  globalSettings          = {'cueMinSeparation', 12, 'fracDuplicated', 0.5, 'trialDuplication', 4};
  vr.numMazesInProtocol   = 6;
  vr.stimulusGenerator    = @PoissonStimulusTrain;
  vr.stimulusParameters   = {'cueVisibleAt', 'cueDensityPerM', 'cueProbability', 'nCueSlots', 'cueMinSeparation'};
  vr.inheritedVariables   = {'cueDuration', 'cueVisibleAt', 'lStart', 'lCue', 'lMemory',...
      'antiFraction','isShaping','meanChoiceReps','turnHint_Mem'};

  
  if nargout < 1
    figure; plot([mazes.lStart] + [mazes.lCue] + [mazes.lMemory], 'linewidth',1.5); xlabel('Shaping step'); ylabel('Maze length (cm)'); grid on;
    hold on; plot([mazes.lMemory], 'linewidth',1.5); legend({'total', 'memory'}, 'Location', 'east'); grid on;
    figure; plot([mazes.lMemory] ./ [mazes.lCue], 'linewidth',1.5); xlabel('Shaping step'); ylabel('L(memory) / L(cue)'); grid on;
    figure; plot([mazes.cueDensityPerM], 'linewidth',1.5); set(gca,'ylim',[0 6.5]); xlabel('Shaping step'); ylabel('Tower density (count/m)'); grid on;
    hold on; plot([mazes.cueDensityPerM] .* (1 - 1./(1 + exp([mazes.cueProbability]))), 'linewidth',1.5);
    hold on; plot([mazes.cueDensityPerM] .* (1./(1 + exp([mazes.cueProbability]))), 'linewidth',1.5);
    hold on; plot([1 numel(mazes)], [1 1].*(100/globalSettings{2}), 'linewidth',1.5, 'linestyle','--');
    legend({'\rho_{L} + \rho_{R}', '\rho_{salient}', '\rho_{distract}', '(maximum)'}, 'location', 'northwest');
    
    [muSalient, muDistract] = poissonCueDensity([mazes.cueDensityPerM], [mazes.cueProbability]);
    disp(significantDigits([muSalient; muDistract] * mazes(end-1).lCue/100, 2));
  end

end
