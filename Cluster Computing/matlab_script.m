function matlab_script( N, Str )

for i = 1:N
    fID = fopen(['output' num2str(i) '.txt'],'w+');
    fprintf(fID,'%s',Str);
    fclose(fID);
end