function [sub_stats3] = grain_measurements_from_map(class_map, tablerank3, areaTH, destinationDir)
    % Extracts statistics for specific phases listed in tablerank3
    
    % 1. Filter class_map to only include desired phases
    target_labels = tablerank3.NewLabel;
    
    % Create a mask for pixels that belong to ANY of the target phases
    relevant_pixels_mask = ismember(class_map, target_labels);
    
    % FIX: Ensure data types match for multiplication
    filtered_class_map = double(class_map) .* double(relevant_pixels_mask);
    
    % 2. Create a label matrix where grains of different classes are separate
    % L needs to hold high values, uint32 is appropriate
    L = zeros(size(filtered_class_map), 'uint32');
    
    current_max_label = 0;
    
    for i = 1:length(target_labels)
        mineral_id = target_labels(i);
        
        % Create binary mask for this specific mineral
        mask = (filtered_class_map == mineral_id);
        
        % Label disconnected grains for this mineral only
        [L_mineral, num_grains] = bwlabel(mask);
        
        % Shift labels to be unique across the whole image
        L_mineral(L_mineral > 0) = L_mineral(L_mineral > 0) + current_max_label;
        
        % Add to combined label matrix
        L(mask) = uint32(L_mineral(mask));
        
        % Update max label count
        current_max_label = current_max_label + num_grains;
    end
    
    % 3. Measure properties for every individual grain
    chosen_vars = {'Area', 'Perimeter', 'Solidity', 'Circularity', ...
                   'Orientation', 'MinorAxisLength', 'MajorAxisLength', ...
                   'Eccentricity', 'EquivDiameter', 'EulerNumber'};
               
    stats = regionprops('table', L, chosen_vars);
    
    % 4. Map these grains back to their Mineral Label ID
    grain_data = regionprops(L, 'PixelIdxList');
    
    mineral_ids = zeros(height(stats), 1);
    for k = 1:height(stats)
        % Get the class_map value for the first pixel of this grain
        % Using filtered_class_map to ensure we get the correct ID
        mineral_ids(k) = filtered_class_map(grain_data(k).PixelIdxList(1));
    end
    stats.Label_ID = mineral_ids;

    % 5. Filter by Area
    stats = stats(stats.Area > areaTH, :);
    
    if isempty(stats)
        sub_stats3 = table(); return;
    end

    % 6. Vectorized Calculations
    stats.Area_ID = (1:size(stats,1))'; 
    stats.aspectRatio = stats.MajorAxisLength ./ stats.MinorAxisLength;
    stats.shapeIndex = stats.Perimeter ./ sqrt(stats.Area);
    stats.numberInclusions = 1 - stats.EulerNumber;

    % 7. Final Organization
    final_order = ['Label_ID', 'Area_ID', 'aspectRatio', 'shapeIndex', 'numberInclusions', chosen_vars];
    sub_stats3 = stats(:, final_order);

    % Save
    if ~exist(destinationDir, 'dir'), mkdir(destinationDir); end
    writetable(sub_stats3, fullfile(destinationDir, 'shape_stats.csv')); 
end