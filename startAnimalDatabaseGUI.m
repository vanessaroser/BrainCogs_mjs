function [dbase, dirs] = startAnimalDatabaseGUI(gui)

if nargin<1
    gui = true;
end

dirs = addGitRepo('General','TankMouseVR','U19-pipeline-matlab');
setenv('DB_PREFIX', 'u19_');

if gui
    dbase = AnimalDatabase();
    dbase.gui('mjs20');
else
    dbase = [];
end