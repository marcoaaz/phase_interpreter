function geopixe_export_all(infoTable, indList, dim, destDir)

%default
pixelPopulations = infoTable.Pixels;
minerals = infoTable.Mineral;

%subset
idx_contained = (pixelPopulations ~= 0);
n_contained = sum(idx_contained);
indList2 = indList(idx_contained);
minerals_contained = minerals(idx_contained);

%changes
char_dim = char(strjoin(string([dim(2), dim(1)]), ',')); %Image dim
change_list = {'Image', 'Note', 'Q'}; %introduced changes    

%% For each mineral mask

for m = 1:n_contained
   
    %Q-vector
    idx_target = indList2{m}; %col-major order
    [col, row] = ind2sub(dim, idx_target); %conversion
    idx_target2 = sub2ind([dim(2), dim(1)], row, col);
    idx_target3 = sort(idx_target2, 'ascend'); %sort (e.g., 90M pixels)
    
    %Update 
    sel_str = minerals_contained{m};
    filename = fullfile(destDir, strcat(sel_str, '.csv'));        

    writeGeopixeRegion_Stream(change_list, {char_dim, sel_str, idx_target3}, filename); 

    fprintf('%s ready..\n', sel_str)
end

end