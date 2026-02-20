function [temp_path, image_size] = floatMatrix_to_tiff(workingDir)

destDir = fullfile(workingDir, 'tiff_float32'); %for images
mkdir(destDir)

%Read compositional data (as image matrix)
table1 = struct2table(dir(fullfile(workingDir, '*.xlsx'))); %csv or xlsx
basenames = table1.name;
pathlist = fullfile(table1.folder, basenames);
n_images = length(pathlist);

%image info
image_size = size(readmatrix(pathlist{1}));

%parse element names
expression1 = '.+\s(?<element>.+)_ppm.*';
struct1 = regexp(table1.name, expression1, 'names');
struct2 = [struct1{:}];
struct3 = struct2table(struct2);
elementlist = struct3.element;

temp_path = fullfile(destDir, strcat(elementlist, '.tiff'));
options.compress= 'no';
options.overwrite = true;
options.message = false;

parfor i = 1:n_images %parfor
    fprintf('Saving %s \n', basenames{i})
    temp_mtx = readmatrix(pathlist{i});    

    idx1 = isnan(temp_mtx); %don't allow NaNs
    idx2 = (temp_mtx < 0); %zeroing
    idx = idx1 | idx2;
    temp_mtx(idx) = 0;  
    
    output_path = temp_path{i};
    saveastiff(single(temp_mtx), output_path, options);
end

end