%   This interface allows for programmatic access and update of the contained data. In your
%   program you should first create an instance of the database to interact with:
%         dbase     = AnimalDatabase();                       % keep this object around for communications
%         dbase.gui();                                        % user interface from which one can add/view animals
%  
%   There are a series of "pull*" functions to retrive info at various levels:
%         [people, templates] = dbase.pullOverview();
%         animals   = dbase.pullAnimalList();                 % all researchers
%         animals   = dbase.pullAnimalList('sakoay');         % a single researcher with ID = sakoay
%         logs      = dbase.pullDailyLogs('sakoay');          % all animals for sakoay
%         logs      = dbase.pullDailyLogs('sakoay','K62');    % a particular animal ID for sakoay
%  
%   To write data to the database, use the following "push*" functions:
%         db.pushAnimalInfo('testuser', 'testuser_T01', 'initWeight', 23.5)
%         db.pushDailyInfo('testuser', 'testuser_T01', 'received', 1.3, 'weight', 22.5);

clearvars;

dirs = addGitRepo('General','TankMouseVR','U19-pipeline-matlab');
setenv('DB_PREFIX', 'u19_');
dbase = AnimalDatabase();
dbase.gui('mjs20');

% db.pushAnimalInfo('mjs20', 'mjs20_', 'initWeight', 23.5)