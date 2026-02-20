function [phasemap_colour, tablerank3] = phasemap_rgb(phasemap1, tablerank1, selected_targets, ...
    sorting_type, destinationDir)
%Generate preview

%Input 
% phasemap1: labeled image after removing artifact classes around the sample fringes
% minerals1: corresponding re-labeled classes
% triplet1: corresponding RGB colours (respecting QuPath)
% minerals_targeted: relevant classes to separate
% sorting_type: selected, non-zero, ranked
% destinationDir: folder to save outputs

%Output
%tablerank2: ordered according to selected_targets (serial labelling)

%Updated: 21-Jan-26, 12-Feb-26, Marco Acevedo

%%

if strcmp(selected_targets, "")
    selected_targets = tablerank1.Mineral';
end

dim = size(phasemap1);
n_rows_original = dim(1);
n_cols_original = dim(2);

minerals1 = tablerank1.Mineral; %PM_names = table2cell(tablerank(:, 2))'
n_masks1 = length(selected_targets);

new_populations = zeros(n_masks1, 1);
found_labels = zeros(n_masks1, 1);
phasemap_modif = zeros(n_rows_original, n_cols_original, 'uint8'); %foreground map
phasemap_serial = zeros(n_rows_original, n_cols_original, 'uint8'); %for rgb
for k = 1:n_masks1
    
    temp_idx = strcmp(minerals1, selected_targets{k});
    label_number = find(temp_idx);    

    mask_temp = (phasemap1 == label_number);
    new_populations(k) = sum(mask_temp, "all"); %if ROI was edited

    phasemap_modif(mask_temp) = label_number; %saving target labels   
    phasemap_serial(mask_temp) = k; %for colouring
    
    found_labels(k) = label_number;    
end

%Rearrange
tablerank2 = tablerank1(found_labels, :); 
minerals2 = minerals1(found_labels);
tablerank2.Pixels = new_populations;
idx1 = (tablerank2.Pixels == 0);

if strcmp(sorting_type, 'selection')
    tablerank3 = tablerank2;
elseif strcmp(sorting_type, 'non-zero')    
    tablerank3 = tablerank2(~idx1, :);
elseif strcmp(sorting_type, 'ranked')
    tablerank3 = sortrows(tablerank2(~idx1, :), 'Pixels', 'descend');
else
    sprintf('Not supported.')
end

%convert to RGB
final_categories = tablerank3.Mineral;
categorical_map0 = categorical(phasemap_modif, found_labels, minerals2);
categorical_map1 = setcats(categorical_map0, final_categories);
triplet2 = [tablerank3.Triplet_1, tablerank3.Triplet_2, tablerank3.Triplet_3];
phasemap_colour = label2rgb(categorical_map1, triplet2, 'k');

%save RGB image for registration
imageFile1 = 'phasemap_target.tif';
imageFile2 = 'phasemap_target_RGB.tif';
fullDest1 = fullfile(destinationDir, imageFile1); 
fullDest2 = fullfile(destinationDir, imageFile2); 

imwrite(phasemap_modif, fullDest1, 'Compression', 'none'); %save tif 24-bit
imwrite(phasemap_colour, fullDest2, 'Compression', 'none'); %save tif 24-bit

end