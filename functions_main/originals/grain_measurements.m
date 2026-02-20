function [sub_stats3] = grain_measurements(binary, tablerank3, areaTH, destinationDir)
%Statistics: grain measurements using binaries (extracted from shapeStatistics_v3.m)

label_ID = tablerank3.NewLabel;
n_labels2 = length(label_ID);

chosen_variables = {
    'Area', 'Perimeter', 'Solidity', 'Circularity', ...
    'Orientation', 'MinorAxisLength', 'MajorAxisLength', 'Eccentricity', ...
    'EquivDiameter', 'EulerNumber'};
calculated_variables = {
    'Label_ID', 'Area_ID', ...
    'aspectRatio', 'shapeIndex', 'numberInclusions'};
variable_names = [calculated_variables, chosen_variables];
n_variables = length(variable_names);

stats_cell = cell(1, n_labels2);
for k = 1:n_labels2
    
    mask_temp = binary{k};
    
    stats = regionprops('table', mask_temp, chosen_variables);
    n_areas = size(stats, 1);
    
    if n_areas > 0
        label_ID2 = repmat(label_ID(k), [n_areas, 1]);
        area_ID = [1:n_areas]';    
        
        %Calculations    
        aspectRatios = stats.MajorAxisLength./stats.MinorAxisLength; %equivalent ellipse
        shapeIndexes = stats.Perimeter./sqrt(stats.Area); %~smoothness and integrity
        n_inclusions = 1 - stats.EulerNumber; %EulerNumber = 1 - number of holes    
        
        stats_temp = addvars(stats, ...
            label_ID2, area_ID, aspectRatios, shapeIndexes, n_inclusions, ...
            'Before', 'Area', 'NewVariableNames', calculated_variables); %Adding labels    
        
    else
        stats_temp = array2table(zeros(1, n_variables), 'VariableNames',variable_names);
        
    end
    stats_cell{k} = stats_temp;
end
stats2 = vertcat(stats_cell{:});
stats3 = stats2(stats2.Area > areaTH, :);%15, optional: filter by area
sub_stats3 = stats3(:, variable_names);

writetable(sub_stats3, fullfile(destinationDir, 'shape_stats.xlsx'))

end