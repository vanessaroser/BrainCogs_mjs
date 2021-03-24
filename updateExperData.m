function fnames = updateExperData(dirs, experiment, subject)

%Notes:
% Set dirs.data = [] to retrieve from bucket
% Set experiment = [] for all experiments

%Aggregate data from all sessions into a single struct and save
create_dirs(dirs.save);

for i = 1:numel(subject)
    %Fetch data from local or bucket
    disp(['Saving data for ' subject(i).ID '...']);
    data = getMouseData(dirs.data, experiment, subject(i));
    %Save
    S = data.(subject(i).ID);
    fnames{i,:} = fullfile(dirs.save,subject(i).ID);
    save(fnames{i},'-struct','S');
end