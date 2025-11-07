function [binary, binary_totals] = binarise_map(class_map, tablerank1)

label_ID = tablerank1.NewLabel';
n_labels2 = length(label_ID);

binary = cell(1, n_labels2);
binary_totals = zeros(1, n_labels2);
for k = 1:n_labels2
    i = label_ID(k);
    temp_binary = (class_map == i); %assuming sequential
    
    binary_totals(k) = sum(temp_binary, 'all');
    binary{k} = temp_binary;
end

end