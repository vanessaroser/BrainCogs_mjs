%Fetch data
key.subject_fullname = 'mjs20_439';
key.block = 1;
fields = {'trial_type', 'choice'};
data = fetch(behavior.TowersBlockTrial & key);
%Get Session Dates
sessionDates = unique({data.session_date})';