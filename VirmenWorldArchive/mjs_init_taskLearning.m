addGitRepo('TankMouseVR','U19-pipeline-matlab');
startup_no_datajoint;

% stimuli = generateUniformStimuli('mjs_memoryMaze.mat', @MJS_MemoryMaze);
generateUniformStimuli('mjs_taskLearning.mat', @MJS_TaskLearning);
mjs_runTaskLearning;