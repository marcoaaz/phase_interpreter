function [AIM, AIM_pct, access_map] = phasemapAIM_fast(map, tablerank3, r, connectivity, destinationDir)

% Extract phase info
label_list = tablerank3.NewLabel;
phase = label_list(label_list ~= 0)';
n_masks = numel(phase);
[rows, cols] = size(map);

% Define structural element (kernel)
diameter = 2*r + 1;
if strcmp(connectivity, 'four')
    sel = strel('diamond', r); % Diamond approximates 4-connectivity
else
    sel = strel('square', diameter); % Square is 8-connectivity
end
kernel = double(sel.getnhood());

% Pre-allocate
frequency = zeros(n_masks, n_masks);
access_map = cell(n_masks, n_masks);

% Generate binary masks once to save memory/time
masks = false(rows, cols, n_masks);
for p = 1:n_masks
    masks(:,:,p) = (map == phase(p));
end

% Main Computation Loop
for i = 1:n_masks
    % Step 1: Find the "influence zone" of Mineral i
    % conv2 is often faster than imdilate for this specific count logic
    influence_zone = conv2(double(masks(:,:,i)), kernel, 'same');
    
    for j = 1:n_masks
        % Skip self-contact if you only want inter-mineral contacts
        % (Though your original code counts them, then removes diagonal later)
        
        % Step 2: Find where Mineral j overlaps with Mineral i's zone
        overlap = (influence_zone > 0) & masks(:,:,j);
        
        % Step 3: Frequency calculation
        % Using the influence_zone values at masks(:,:,j) locations 
        % mimics your 'counts' logic exactly
        contact_counts = influence_zone .* masks(:,:,j);
        frequency(i, j) = sum(contact_counts, 'all');

        % Step 4: Access Map (Spatial Adjacency)
        % Optimization: only store sparse or logical if possible to save 2GB+ space
        if any(overlap, 'all')
            temp_access = zeros(rows, cols, 'uint8'); % Use smaller data type
            temp_access(overlap) = phase(i);
            access_map{i, j} = temp_access;
        else
            access_map{i, j} = sparse(rows, cols);
        end
    end
end

% --- Normalization (Matches your original logic) ---
frequency_sum = sum(frequency, 'all');
AIM = (1/frequency_sum) * frequency;

% Remove diagonal for AIM_pct
AIM_woD = AIM;
AIM_woD(logical(eye(size(AIM)))) = 0; 

AIM_sum = sum(AIM_woD, 1);
AIM_pct = 100 * AIM_woD ./ (AIM_sum + eps); % eps prevents div by zero

% Saving (as per your requirement)
if ~exist(destinationDir, 'dir'); mkdir(destinationDir); end
writematrix(AIM, fullfile(destinationDir, 'AIM.csv'));
writematrix(AIM_pct, fullfile(destinationDir, 'AIM_pct.csv'));
save(fullfile(destinationDir, 'access_map.mat'), 'access_map', '-v7.3');

end