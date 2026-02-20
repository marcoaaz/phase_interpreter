function [adjacency_map] = adjacencyCheck_fast(class_map, access_map, tablerank1, destinationDir)

minerals2 = tablerank1.Mineral;
triplet2 = [tablerank1.Triplet_1, tablerank1.Triplet_2, tablerank1.Triplet_3];
fg_labels = tablerank1.NewLabel; % Ensure this is a vector
n_labels = length(minerals2);
[rows, cols] = size(class_map);

adjacency_map = cell(1, n_labels);

for i = 1:n_labels    
    sel = fg_labels(i);
    binary_temp = (class_map == sel);
    
    % Initialize map for this mineral
    temp_map = zeros(rows, cols, 'uint16'); 
    
    % Get indices of all other minerals
    other_indices = find((1:n_labels) ~= i);
    
    for idx = other_indices
        % Force logical indexing to prevent the "positive integer" error
        adj_mask = access_map{i, idx};
        if ~islogical(adj_mask)
            adj_mask = logical(adj_mask);
        end
        
        % Assign the NewLabel value to the pixels
        if any(adj_mask, 'all')
            temp_map(adj_mask) = fg_labels(idx);
        end
    end

    % --- Fast RGB Generation ---
    % Start with your specified foreground color (e.g., White 255)
    % Using uint8 to save 3x memory compared to double
    R = uint8(binary_temp) * 255;
    G = R; B = R;

    % Color the adjacent regions
    for idx = other_indices
        % Find where this specific neighbor was recorded in temp_map
        color_mask = (temp_map == fg_labels(idx));
        
        if any(color_mask, 'all')
            R(color_mask) = uint8(triplet2(idx, 1) * 255);
            G(color_mask) = uint8(triplet2(idx, 2) * 255);
            B(color_mask) = uint8(triplet2(idx, 3) * 255);
        end
    end
    
    combined_RGB = cat(3, R, G, B);

    % Save immediately to free up pipeline
    temp_name = sprintf('phasemap_adjacency_%s.tif', minerals2{i});
    imwrite(combined_RGB, fullfile(destinationDir, temp_name), ...
        'compression', 'none'); %'lzw' good for flat area compression

    % Store in cell (Warning: Watch your RAM with 11k x 18k images!)
    adjacency_map{i} = temp_map;    
    
    % fprintf('Processed mineral %d of %d: %s\n', i, n_labels, minerals2{i});
end
end