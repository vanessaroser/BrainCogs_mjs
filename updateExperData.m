function fnames = updateExperData( data, dirs )

%Aggregate data from all sessions into a single struct and save
create_dirs(dirs.results);
subjectID = fieldnames(data);
for i = 1:numel(subjectID)
    fnames{i,:} = fullfile(dirs.results,subjectID{i});
    disp(['Saving ' fnames{i} '...']);
    S = data.(subjectID{i});
    save(fnames{i},'-struct','S');
end