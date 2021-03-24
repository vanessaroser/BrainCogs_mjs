clearvars;
[db, dirs] = setupDataJoint;

researcherID = 'mjs20';
animalID = "mjs20_439";
% animalID = ["mjs20_439","mjs20_665","mjs20_441","mjs20_443","mjs20_447","mjs20_449","mjs20_658"];
% logs = db.pullDailyLogs(researcherID, animalID)
% [researcher, iResearcher] = db.findResearcher(researcherID);

for i=1:numel(animalID)
% [logs, animal, researcher] = pushDailyInfo(db, researcherID, animalID(i), varargin)
end

%Some Example Code:
% % get the connection object
% session = Session
% connection = session.conn
% 
% % insert Session and Session.Experimenter entries in a transaction
% connection.startTransaction
% try
%     key.subject_id = animal_id;
%     key.session_time = session_time;
% 
%     session_entry = key;
%     session_entry.brain_region = region;
%     insert(Session, session_entry)
% 
%     experimenter_entry = key;
%     experimenter_entry.experimenter = username;
%     insert(SessionExperimenter, experiment_entry)
%     connection.commitTransaction
% catch
%     connection.cancelTransaction
% end