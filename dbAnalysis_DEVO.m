
clearvars;

% exper = ["mjs_memoryMaze_NAc_DREADD_performance"];
exper = []; %If empty, fetch data from all experiments
startDate = datetime('2021-02-08');
subject = ["mjs20_439","mjs20_665","mjs20_441","mjs20_443","mjs20_447","mjs20_449","mjs20_658"];
rigNum = ["rig1","rig2","rig3","rig4","rig5","rig6","rig7"];

dataPath = fullfile('C:','Data','MemoryMaze','data');
savePath = fullfile('C:','Data','MemoryMaze','results',exper);

%Hyperparameters
fetch_data = true; %

if fetch_data
    %Retrieve data from logfiles
    data = getMouseData(dataPath,exper,subject,rigNum); %Set 'dataPath' = [] to retrieve from bucket
    %Aggregate data from each mouse into a single struct and save
    create_dirs(savePath);
    for i = 1:numel(subject)
        disp(['Saving data for ' subject{i} '...']);
        S = data.(subject(i));
        save(fullfile(savePath,subject(i)),'-struct','S');
    end
    clearvars S data
end

%Calculate daily reward volume
for i = 1:numel(subject)
    data = load(fullfile(savePath,subject(i)));
    
    %Initialize session variables
    date = zeros(numel(data.logs),6); 
    rewEarned = NaN(numel(data.logs),1);
    
    for j = 1:numel(data.logs)               
        %Get total reward volume for each day by summing blocks
        rewardMiL = 0;
        for k = 1:length(data.logs(j).block)
            rewardMiL = rewardMiL + data.logs(j).block(k).rewardMiL;
        end
        date(j,1:3) = data.logs(j).session.start(1:3); %Remove time
        rewEarned(j,:) = rewardMiL;
    end
    
    %Initialize table variables
    sessionDate = datetime(date,'format','yyyy-MM-dd');
    Date = (startDate:sessionDate(end))'; %All set to 00:00:00 for indexing by date
    Earned = NaN(numel(Date),1);
%     Earned(ismember(Date,sessionDate)) = rewEarned;
    Supplementary = NaN(numel(Date),1);
    Weight = NaN(numel(Date),1);
    
    %Load existing table and append new data
    excelPath = fullfile(savePath,'Daily_Intake.xls');
    if exist(excelPath,'file') && ismember(subject(i),sheetnames(excelPath))
        %Update table
        T = readtable(excelPath,'Sheet',subject(i));
        newRows = abs(size(T,1)-size(Date,1));
        if size(Date,1)>size(T,1)
            %Add rows to existing sheet
            T2 = table(Date,Earned,Supplementary,Weight);
            idx = [false(size(Date,1)-newRows,1); true(newRows,1)];
            T = [T; T2(idx,:)];
        else %Fill in missing values
            T.Date = (startDate:startDate+size(T,1)-1)';
%             T.Earned = [Earned; NaN(newRows,1)];
            % T.Weight = [];
            % T.Supplementary = [];
        end
        T.Earned(ismember(Date,sessionDate)) = rewEarned;
    else
        T = table(Date,Earned,Supplementary,Weight);
    end
    
    writetable(T,excelPath,'Sheet',subject(i));
    
    data.dailyIntake = T;
    save(fullfile(savePath,subject(i)),'-struct','data');
    
%     T.Earned = Earned;
%     T.Date = Date;
end

% db.pushAnimalInfo('mjs20', 'mjs20_', 'initWeight', 23.5)