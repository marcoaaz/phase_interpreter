function [tablerank1, phasemap1] = edit_phasemap(phasemap0, tablerank, destinationDir)

n_phases = size(tablerank, 1);

%relabelling phase map
tablerank1 = tablerank;
tablerank1.NewLabel = (1:n_phases)';

phasemap1 = zeros(size(phasemap0), 'uint8'); %preallocate
for i = 1:n_phases
    temp_original = tablerank1.Label(i) + 1; %for new mapping
    temp_new = tablerank1.NewLabel(i); %find ranking

    mask_phase = (phasemap0 == temp_original);    
    phasemap1(mask_phase) = temp_new;%re-labelling     
end

%Save
fileName2 = fullfile(destinationDir, 'species.xlsx');
fileName3 = fullfile(destinationDir, 'phasemap_label_full.tif');

writetable(tablerank1, fileName2, 'Sheet', 'phaseMap', 'WriteMode', 'overwritesheet'); %no overwrite
imwrite(phasemap1, fileName3); %labelled image (all classes)

end