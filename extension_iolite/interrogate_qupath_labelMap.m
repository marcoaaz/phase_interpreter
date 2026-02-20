function [masks2] = interrogate_qupath_labelMap(filepath1, segmentationDir, ...
    desired, coordinates_int)
%interrogation of scattered grid

filepath2 = fullfile(segmentationDir, 'phasemap_label_full.tif');
filepath3 = fullfile(segmentationDir, 'species'); 
destDir1 = fullfile(segmentationDir, 'generated_iolite_masks');
mkdir(destDir1)

table_xy = readtable(filepath1, 'VariableNamingRule','preserve');
coordinates = [table_xy.X, table_xy.Y];

%phase map metadata
table_temp = readtable(filepath3, 'Sheet','phaseMap');
minerals_temp = table_temp.Mineral;
labels_temp = table_temp.NewLabel;
minerals_temp

%interrogating label map
label_img = imread(filepath2);
rows = coordinates_int(:, 2);
cols = coordinates_int(:, 1);
indices = sub2ind(size(label_img), rows, cols);
pixval = label_img(indices);

%building table
masks1 = [coordinates, double(pixval)];
masks2 = array2table(masks1);
masks2.Properties.VariableNames(1:end) = {'x', 'y', 'phase'};

%subsetting by target mineral(s)
n_desired = length(desired);
for m = 1:n_desired
    name_temp = desired{m};
    
    %find names (qupath annotations)
    idx_temp = strcmp(minerals_temp, name_temp);
    
    %subset
    label_temp = labels_temp(idx_temp);
    idx_mask = (masks2.phase == label_temp);
    masks3 = masks2(idx_mask, :);

    path_temp = fullfile(destDir1, strcat(name_temp, '.csv'));    
    writetable(masks3, path_temp)
end

end