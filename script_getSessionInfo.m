IDs = ["mjs20_09","mjs20_10"];
for i=1:numel(IDs)
    S = subjects([subjects.ID]==IDs(i));
    sessionIdx = [S.sessions.session_date]==datetime("28-Oct-2021");
    disp(S.ID)
    disp(S.sessions(sessionIdx).session_date);
    disp(S.logs(sessionIdx).session);
end