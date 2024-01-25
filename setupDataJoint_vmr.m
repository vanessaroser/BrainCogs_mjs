function out = setupDataJoint_vmr()

setenv('DB_PREFIX','u19_'); 
setenv('DJ_USER','vr2617'); %Fill in username
setenv('DJ_PASS','T1nkerbe11eT1ger'); %Fill in password
out  = dj.conn('datajoint00.pni.princeton.edu', getenv('DJ_USER'), getenv('DJ_PASS'), '', true);

%--------------------------------------------------------------------
% Syntax for dj.conn:
% connObj = conn(host, user, pass, initQuery, reset, use_tls, nogui)
%
% Save setupDataJoint_mjs as p-file