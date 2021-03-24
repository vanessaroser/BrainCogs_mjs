% Generate Tables to Record Daily Intake and Weight
function dataStruct = dailyIntakeTable(dirs, experiment, subject)

%Retrieve data from logfiles
data = getMouseData(dirs.data,experiment,subject); %Set 'dataPath' = [] to retrieve from bucket

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
        rewardMiL = 0;
        for k = 1:length(logData(j).block)
            rewardMiL = rewardMiL + logData(j).block(k).rewardMiL;
        end
        date(j,1:3) = logData(j).session.start(1:3); %Remove time
        rewEarned(j,:) = rewardMiL;
    end
    sessionDate = datetime(date,'format','yyyy-MM-dd');
    
    %Table variables
    Date = (startDate : sessionDate(end))'; %All set to 00:00:00 for indexing by date
    Earned = NaN(numel(Date),1);
    Supplementary = NaN(numel(Date),1);
    Weight = NaN(numel(Date),1);
       
    %Load existing table and append new data
    excelPath = fullfile(dirs.save,'Daily_Intake.xls');
    if exist(excelPath,'file') && ismember(subjID,sheetnames(excelPath))
        %Update table
        T = readtable(excelPath,'Sheet',subjID);
        newRows = abs(size(T,1)-size(Date,1));
        if size(Date,1)>size(T,1)
            %Add rows to existing sheet
            T2 = table(Date,Earned,Supplementary,Weight);
            idx = [false(size(Date,1)-newRows,1); true(newRows,1)];
            T = [T; T2(idx,:)];
        else %Fill in missing values
            T.Date = (startDate : startDate+size(T,1)-1)';
        end
    else
        T = table(Date,Earned,Supplementary,Weight);
    end
    T.Earned(ismember(T.Date,sessionDate)) = rewEarned;
    
    dataStruct.(subjID) = T;
    writetable(T,excelPath,'Sheet',subjID);
end
%Save as MAT
save(fullfile(dirs.save,'Daily_Intake'),'-struct','dataStruct');