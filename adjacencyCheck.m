
function [adjacency_map, adjacency_rgb] = adjacencyCheck(class_map, access_map, tablerank1, destinationDir)
%*Adjacency (or accessibility) maps (Kim et al., 2022). 

minerals2 = tablerank1.Mineral;
triplet2 = [tablerank1.Triplet_1, tablerank1.Triplet_2, tablerank1.Triplet_3];
fg_labels = tablerank1.NewLabel';  %transpose

%Adjacency phase maps
n_labels = length(minerals2);
rows = size(class_map, 1);
cols = size(class_map, 2);

%Plot aspect

% fgColor = 0.4*[1, 1, 1]; 
% bgColor = rgb('SkyBlue'); %background
fgColor = 1*[1, 1, 1]; 
bgColor = 0*[1, 1, 1]; %background

adjacency_map = cell(1, n_labels);
adjacency_rgb = cell(1, n_labels);
for i = 1:n_labels    
    sel = fg_labels(i); %inner mineral to watch and understand

    binary_temp = (class_map == sel);    
    mineral_mask = label2rgb(binary_temp, fgColor, bgColor);
    
    %Neighbour labels
    [not_selected, not_selected_idx] = setdiff(fg_labels, sel);    
    triplet3 = triplet2(not_selected_idx, :);
    
    n_dif = length(not_selected);    
    temp_map = zeros(rows, cols, 'uint8'); %double also supported
    for j = 1:n_dif 
        idx = not_selected_idx(j);
        binary_adj_temp = logical(access_map{i, idx}); %label to binary mask
        
        not_sel = not_selected(j);        
        temp_map(binary_adj_temp) = not_sel; %labelling           
        
    end
    
    %Medicine: use categorical to avoid having to renumber   
    labels2 = string(not_selected);    
    temp_map2 = categorical(string(temp_map), labels2, "Ordinal", true);
        
    %generate map
    %Note: foreground border pixels will be coloured according to neighbour phase
    B = labeloverlay(mineral_mask, temp_map2, ...
        'Colormap', triplet3, 'Transparency', 0, 'IncludedLabels', labels2); 
        
    %save
    temp_name = strcat('phasemap_adjacency_', minerals2{i}, '.tif');
    imwrite(B, fullfile(destinationDir, temp_name), 'compression', 'none')
    
    %return
    adjacency_map{i} = temp_map;
    adjacency_rgb{i} = B;
end

%debug: 
% figure, imshow(adjacency_rgb{sel})
% title(strcat('Adjacency of', {' '}, string_C2{sel}))

end