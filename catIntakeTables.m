function T = catIntakeTables( intake, save_dir )

%Concatenate tables for use in DB
T = table;
subjID = fieldnames(intake);
for i = 1:numel(subjID)
    T = [T; intake.(subjID{i})];
end
writetable(T,fullfile(save_dir,'Daily_Intake_All_Subjects.xls'));