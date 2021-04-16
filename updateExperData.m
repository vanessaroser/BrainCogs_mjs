function fnames = updateExperData( subjects, dirs )

%Aggregate data from all sessions into a single struct and save
create_dirs(dirs.results);
for i = 1:numel(subjects)
    subjectID = subjects(i).ID;
    fnames{i,:} = fullfile(dirs.results,subjectID);
    disp(['Saving ' fnames{i} '...']);
    S = subjects(i);
    save(fnames{i},'-struct','S');
end