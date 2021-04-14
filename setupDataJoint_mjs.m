function out = setupDataJoint_mjs()

setenv('DB_PREFIX','u19_');
setenv('DJ_USER','mjs20');
setenv('DJ_PASS','Peace be with you');
out  = dj.conn('datajoint00.pni.princeton.edu', '', '', '', '', true);