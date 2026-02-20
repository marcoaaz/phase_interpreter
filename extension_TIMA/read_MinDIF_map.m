function [phasemap, section_mask, tablerank] = read_MinDIF_map(montage_Info, table_mineral2,...
    class_bg, kernel_size)

%Updated: 21-Jan-26, Marco Acevedo


%retrieving information
experiment_path = montage_Info.experiment_path;
metadata1 = montage_Info.metadata1;
mapping = montage_Info.mapping; 
dim = montage_Info.dim;
n_rows_original = dim(1);
n_cols_original = dim(2);
tileSize_px = montage_Info.tileSize_px;
% dim_tiles = montage_Info.dim_tiles; %tiles across
n_tiles = size(mapping, 1);

%Follow read_qupath_map.m convention
minerals = table_mineral2.Mineral;
original_labels = table_mineral2.Label;
triplet = table_mineral2{:, {'Triplet_1', 'Triplet_2', 'Triplet_3'}};

%% Stitching phase map

structure_temp = struct2table(dir(fullfile(experiment_path, 'fields', '**', 'phases.tif')));
folder_temp = fullfile(structure_temp.folder, structure_temp.name);
folder_temp = string(folder_temp);

[a, ~, ~]= fileparts(folder_temp);
[~, folderName_temp, ~] = fileparts(a);     
folderName_temp = str2double(folderName_temp);

%info
image_reference = imread(folder_temp(1));
image_size = [tileSize_px, tileSize_px];
image_class = class(image_reference);

phasemap_original0 = zeros(dim, image_class);
for j = 1:n_tiles
    index_temp = folderName_temp == mapping(j, 2); %oldLabel
    folderName_temp1 = mapping(j, 1);       

    %Allocating: step not stored in memory
    if sum(index_temp) > 0  

        image_temp = imread(folder_temp(index_temp)); %reading 
        
        %finding coordinates
        index_temp2 = metadata1.Tile == mapping(j, 2);
        from_col = metadata1.X(index_temp2) + 1;
        from_row = metadata1.Y(index_temp2) + 1;
        to_col = from_col + tileSize_px - 1;
        to_row = from_row + tileSize_px - 1;

        phasemap_original0(from_row:to_row, from_col:to_col) = image_temp;

    elseif sum(index_temp) == 0               
        
        continue
        % image_temp = zeros(image_size, image_class);                     
    end            
end
phasemap_original = phasemap_original0 + 1; %TIMA naming (-1)

%% Zeroing background classes and fixing margin artifacts

n_bg = length(class_bg);
adequate_test = sum(ismember(class_bg, minerals));
bg_mask = false(n_rows_original, n_cols_original);

bg_label = [];
if adequate_test > 0    
    
    for m = 1:n_bg
        bg_string1 = class_bg{m};
        temp_label = find(strcmp(minerals, bg_string1)); %depends on class names
        temp_mask = (phasemap_original == temp_label); %assuming they are ordered
    
        bg_mask = bg_mask | temp_mask;
        bg_label = [bg_label, temp_label];
    end
    fg_mask = ~bg_mask; %default    

    %Finding foreground
    fg_mask_filled = fg_mask;
        
    %No cropping    
    width_mask = n_cols_original; %for Laser routine
    height_mask = n_rows_original;        
    phasemap = phasemap_original(1:height_mask, 1:width_mask);    
    section_mask0 = fg_mask_filled(1:height_mask, 1:width_mask); 
    
    section_mask = section_mask0;

elseif adequate_test == 0
    
    phasemap = phasemap_original;
    section_mask = ~bg_mask;    
end

phasemap(~section_mask) = 0; %zeroing background classes


%% Mineral table

n_labels = length(minerals);

population = zeros(1, n_labels);
for i = 1:n_labels   
    temp_index = phasemap_original0 == i-1; %for matching TIMA MinDIF convention
    population(i) = sum(temp_index, 'all');
end

tablerank_original = table(original_labels, minerals, population', triplet, ...
    'VariableNames', {'Label', 'Mineral', 'Pixels', 'Triplet'});

label2 = tablerank_original.Label + 1; %for new mapping

bg_index = ismember(label2, bg_label); %remove background
tablerank0 = tablerank_original(~bg_index, :); 

tablerank = sortrows(tablerank0, 'Pixels', 'descend'); %sort by number of pixels

end