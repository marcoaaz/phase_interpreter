
function [phasemap, section_mask, tablerank] = read_qupath_map(classifierName, class_bg, minerals, triplet, kernel_size, destinationDir)

suffix = '.ome.tif';
phasemap_inputName = strcat(classifierName, suffix);%default

%Reading Phase Map image pyramid (OME-TIFF)
parentDir = fileparts(destinationDir);
input_file = fullfile(parentDir, phasemap_inputName);
data = bfopen(input_file); %default
series1 = data{1, 1};
series1_plane1 = series1{1, 1}; %unmodified
original_labels = unique(series1_plane1); 

% seriesCount = size(data, 1);
% series1_planeCount = size(series1, 1);
% series1_label1 = series1{1, 2};
% series1_colorMap1 = data{1, 3}{1, 1};
% metadataList = data{1, 2};

%quPath naming (-1)
phasemap_original = series1_plane1 + 1; 
n_rows_original = size(phasemap_original, 1);
n_cols_original = size(phasemap_original, 2);

%% Zeroing background classes and fixing margin artifacts

n_bg = length(class_bg);
adequate_test = sum(ismember(class_bg, minerals));
bg_mask = false(n_rows_original, n_cols_original);

bg_label = [];
if adequate_test > 0    
    
    for m = 1:n_bg
        bg_string1 = class_bg{m};
        temp_label = find(strcmp(minerals, bg_string1)); %depends on QuPath class names
        temp_mask = (phasemap_original == temp_label);
    
        bg_mask = bg_mask | temp_mask;
        bg_label = [bg_label, temp_label];
    end
    fg_mask = ~bg_mask; %default    

    %Finding foreground
    if kernel_size == 0
        fg_mask_filled = imfill(bwareafilt(fg_mask, 2), 'holes');
    elseif kernel_size >= 1
        se = strel("diamond", kernel_size); %30
        fg_mask_filled = imfill(imdilate(fg_mask, se), 'holes');
    end
    
    %No cropping    
    width_mask = n_cols_original; %for Laser routine
    height_mask = n_rows_original;        
    phasemap = phasemap_original(1:height_mask, 1:width_mask);    
    section_mask0 = fg_mask_filled(1:height_mask, 1:width_mask); 

    section_mask = bwareafilt(section_mask0, 1); %Keeping largest area (map)   

elseif adequate_test == 0
    
    phasemap = phasemap_original;
    section_mask = ~bg_mask;    
end

phasemap(~section_mask) = 0; %zeroing background classes


%% Mineral table

n_labels = length(minerals);

population = zeros(1, n_labels);
for i = 1:n_labels   
    temp_index = series1_plane1 == i-1; %for matching QuPath convention
    population(i) = sum(temp_index, 'all');
end

tablerank_original = table(original_labels, minerals, population', triplet, ...
    'VariableNames', {'Label', 'Mineral', 'Pixels', 'Triplet'});

label2 = tablerank_original.Label + 1; %for new mapping

bg_index = ismember(label2, bg_label); %remove background
tablerank0 = tablerank_original(~bg_index, :); 

tablerank = sortrows(tablerank0, 'Pixels', 'descend'); %sort by number of pixels

end