function dbase = startAnimalDatabaseGUI()

%Edit path to code repo
dirs.code = fullfile('C:','Users','mjs20','Documents','GitHub'); %Parent directory for ../General, containing addGitRepo.m
addpath(genpath(fullfile(dirs.code,'General')));
addGitRepo(dirs,'General','TankMouseVR','U19-pipeline-matlab'); %TankMouseVR and U19-pipeline... are required

%Set environment variables
netID = 'mjs20';
password = 'Peace be with you';
setenv('DB_PREFIX','u19_');
setenv('DJ_USER',netID); %Edit to specify netID
setenv('DJ_PASS',password); %Edit to specify PNI password

%Call database function and load GUI
dbase = AnimalDatabase();
dbase.gui(netID);

end