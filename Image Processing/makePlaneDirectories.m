%Copy z-stacks each to their own individual directory
data_dir = 'Z:\Users\msiniscalchi\220603 M410 vessels';
parent_dir = fileparts(data_dir);
files = dir(data_dir);
files = files([files.isdir]==false);

stack_dir = string(numel(files),1);
for i = 1:numel(files)
    stack_dir(i) = fullfile(parent_dir,'movement-correction',files(i).name(1:end-4));
    mkdir(stack_dir);
    copyfile(fullfile(data_dir,files(i).name),fullfile(stack_dir,files(i).name));
end

%Run iCorre and stitch
