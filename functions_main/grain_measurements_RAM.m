function [sub_stats3] = grain_measurements_RAM(binary, tablerank3, areaTH, destinationDir)
%RAM save version of grain_measurements()

label_ID = tablerank3.NewLabel;
n_labels = length(label_ID);

chosen_vars = {'Area', 'Perimeter', 'Solidity', 'Circularity', ...
               'Orientation', 'MinorAxisLength', 'MajorAxisLength', ...
               'Eccentricity', 'EquivDiameter', 'EulerNumber'};

% We use a cell array to store only the SMALL filtered tables
results_cell = cell(n_labels, 1);

for k = 1:n_labels
    % 1. Extract ONE mask
    mask_temp = binary{k}; 
    
    % If the mask is sparse, regionprops handles it, but full is often faster 
    % if it's already in the cell as full.
    stats = regionprops('table', mask_temp, chosen_vars);
    
    % 2. IMMEDIATE FILTERING (Crucial for RAM)
    % Most grains in thin sections are tiny noise. Removing them now 
    % reduces the table size by 90% before it hits your RAM.
    if ~isempty(stats)
        stats = stats(stats.Area > areaTH, :);
    end
    
    if ~isempty(stats)
        % 3. Add Label ID
        stats.Label_ID = repmat(label_ID(k), height(stats), 1);
        results_cell{k} = stats;
    end
    
    % 4. FORCE CLEARANCE
    % Explicitly help MATLAB's garbage collector
    clear stats mask_temp 
end

% Combine the now-tiny filtered tables
sub_stats3 = vertcat(results_cell{:});

if isempty(sub_stats3)
    return;
end

% 5. Vectorized Math on the reduced dataset
sub_stats3.Area_ID = (1:height(sub_stats3))';
sub_stats3.aspectRatio = sub_stats3.MajorAxisLength ./ sub_stats3.MinorAxisLength;
sub_stats3.shapeIndex = sub_stats3.Perimeter ./ sqrt(sub_stats3.Area);
sub_stats3.numberInclusions = 1 - sub_stats3.EulerNumber;

% Final Reordering
final_order = ['Label_ID', 'Area_ID', 'aspectRatio', 'shapeIndex', 'numberInclusions', chosen_vars];
sub_stats3 = sub_stats3(:, final_order);

% Save
if ~exist(destinationDir, 'dir'), mkdir(destinationDir); end
writetable(sub_stats3, fullfile(destinationDir, 'shape_stats.csv'));

end