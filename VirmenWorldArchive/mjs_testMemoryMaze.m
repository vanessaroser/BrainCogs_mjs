function mjs_testMemoryMaze(numDataSync, varargin)

if nargin < 1
    numDataSync = [];
end

name = getenv('COMPUTERNAME');
switch name
    case 'homePC' %Edit for home Desktop
    dataPath = 'J:\Data & Analysis\VRMemoryMaze';
    case 'PNI-F4W2YM2' %PNI Desktop for DEVO
    dataPath = 'C:\Data\VRMemoryMaze';
    otherwise %Training Rigs, etc.
    dataPath = 'C:\Data\msiniscalchi';   
end

experName = 'mjs_memoryMaze';
cohortName = 'test';

runCohortExperiment(dataPath, experName, cohortName, numDataSync, varargin{:});

end