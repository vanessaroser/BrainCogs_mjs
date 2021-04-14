function [dbase, dirs] = startAnimalDatabaseGUI()

dirs = addGitRepo('General','TankMouseVR','U19-pipeline-matlab');
setenv('DB_PREFIX','u19_');
setenv('DJ_USER','mjs20');
setenv('DJ_PASS','Peace be with you');

dbase = AnimalDatabase();
dbase.gui('mjs20');

end