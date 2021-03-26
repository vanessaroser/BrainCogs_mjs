% Generate Tables to Record Daily Intake and Weight

function intake = dailyIntakeTable(data, dirs, subject)

%Retrieve data from logfiles
if isempty(data)
    %Set 'dataPath' = [] to retrieve from bucket
    %Set 'experiment' = [] for all experiments
    data = getMouseData([],[],subject); %data = getMouseData(dataPath,experiment,subject)
end

%Calculate daily reward volume
for i = 1:numel(subject)

    %Unpack
    subjID = subject(i).ID;
    startDate = subject(i).startDate;
    
    %Initialize session variables
    logData = data.(subjID).logs;
    date = zeros(numel(logData),6); 
    rewEarned = NaN(numel(logData),1);
   
    %Get total reward volume for each day by summing blocks
    for j = 1:numel(logData)               
        date(j,1:3) = logData(j).session.start(1:3); %Remove time
        rewEarned(j,:) = sum([logData(j).block(:).rewardMiL]);
    end
    sessionDate = datetime(date,'format','yyyy-MM-dd');
    
    %Initialize table variables
    date = (startDate : sessionDate(end))'; %All set to 00:00:00 for indexing by date
    subject_fullname = string(repmat(subject(i).ID,numel(date),1));
    earned = NaN(numel(date),1);
    supplementary = NaN(numel(date),1);
    weight = NaN(numel(date),1);
       
    %Load existing workbook and append new data
    excelPath = fullfile(dirs.save,'Daily_Intake.xls');
    if exist(excelPath,'file') && ismember(subjID,sheetnames(excelPath))
        %Update table
        T = readtable(excelPath,'Sheet',subjID,'TextType','string');
        newRows = abs(size(T,1)-size(date,1));
        if size(date,1)>size(T,1)
            %Add rows to existing sheet
            T2 = table(subject_fullname,date,earned,supplementary,weight);
            idx = [false(size(date,1)-newRows,1); true(newRows,1)];
            T = [T; T2(idx,:)];
        end
    else %Generate new table
        T = table(subject_fullname,date,earned,supplementary,weight);
    end
    
    %Fill in subject IDs, dates and earned reward amounts
    T.subject_fullname(1:end) = subject(i).ID;
    T.date(1:end) = (startDate : startDate+size(T,1)-1)';
    T.earned(ismember(T.date,sessionDate)) = rewEarned;
    
    %Write table for current subject as XLS sheet
    intake.(subjID) = T;
    writetable(T,excelPath,'Sheet',subjID);
end

%Concatenate tables for use in DB
T = table;
subjID = fieldnames(intake);
for i = 1:numel(subjID)
    T = [T; intake.(subjID{i})];
end
writetable(T,fullfile(dirs.save,'Daily_Intake_All_Subjects.xls'));

%Save as MAT
save(fullfile(dirs.save,'Daily_Intake'),'-struct','intake');