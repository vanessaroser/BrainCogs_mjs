function data = getMouseData(dataPath,exper,subject)

if isempty(exper)
    exper = " ";
end

%Aggregate log data into single struct by subject
for i=1:numel(subject)

    %Fetch data from bucket if not copied locally
    subjID = subject(i).ID;
    if isempty(dataPath)
        dirs.data(i,:) = ...
            fullfile('Y:','RigData','training',rigNum(i),'msiniscalchi','data',subjID);
    else %Local copies by subject ID at 'dataPath'
        dirs.data(i,:) = fullfile(dataPath,subjID);
    end
    
    %List data from specific experiment, or all if isempty(exper)
    list = dir([char(fullfile(dirs.data(i,:),exper)),'*.mat']);
    [~,idx] = sort([list.datenum]);
    data.(subjID).fnames = {list(idx).name}';

    %Load each matfile and aggregate into structure
    for j = 1:numel(data.(subjID).fnames)
        disp(['Loading ' data.(subjID).fnames{j} '...']);
        S = load(fullfile(dirs.data(i,:), data.(subjID).fnames{j}));
        data.(subjID).logs(j,:) = S.log;       
    end
end