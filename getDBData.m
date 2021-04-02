function data = getDBData( subjects, varargin)

% table data requested will be specified in 'varargin'
    
%Water administration and weighing data
for i = 1:numel(subjects)
    query = ...
        proj(action.Weighing, 'date(weighing_time)->administration_date', 'weight', 'weigh_person')...
        * action.WaterAdministration & struct('subject_fullname', subjects(i).ID);
    data.intake.(subjects(i).ID) = fetch(query,'*');
end

%Behavior session data
for i = 1:numel(subjects)
    query = proj(behavior.TowersBlock,...
        'level','n_trials','block_duration','reward_mil','reward_scale','block_performance')...
        & struct('subject_fullname', subjects(i).ID);
    data.performance.(subjects(i).ID) = fetch(query,'*');
end

% writeDB_fromXLS('Daily_Intake.xls', {action.Weighing, action.WaterAdministration})

% tables{i}.tableHeader.names

% addpath(genpath('../../pipelines'))
% setenv('DB_PREFIX', 'u19_')
% 
% host = env('DJ_HOST');
% user = env('DJ_USER');
% pw = env('DJ_PASSWORD');
% dj.conn(host, user, pw)


%     subjID = subject(i).ID;
%     startDate = subject(i).startDate;
%     
%     %Initialize session variables
%     logData = data.(subjID).logs;
%     administration_date = zeros(numel(logData),6); 
%     rewEarned = NaN(numel(logData),1);
%    
%     %Get total reward volume for each day by summing blocks
%     for j = 1:numel(logData)               
%         Date(j,1:3) = logData(j).session.start(1:3); %Remove time
%         rewEarned(j,:) = sum([logData(j).block(:).rewardMiL]);
%     end
%     sessionDate = datetime(Date,'format','yyyy-MM-dd');