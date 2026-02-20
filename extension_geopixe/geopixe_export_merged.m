function geopixe_export_merged(infoTable, requestedMinerals, indList, dim, workingDir)

%default
pixelPopulations = infoTable.Pixels;
minerals = infoTable.Mineral;

%subset
idx_contained = (pixelPopulations ~= 0);
indList2 = indList(idx_contained);
minerals_contained = minerals(idx_contained);
% minerals_contained

%changes
char_dim = char(strjoin(string([dim(2), dim(1)]), ',')); %Image dim
change_list = {'Image', 'Note', 'Q'}; %introduced changes    

%% For custom mineral mask

[~, idx_temp] = ismember(requestedMinerals, minerals_contained);
positive_idx = ~(idx_temp == 0);
idx_temp2 = idx_temp(positive_idx);

requestedTarget = [];
for k = idx_temp2    

    %Q-vector
    idx_target = indList2{k}; %col-major order
    [col, row] = ind2sub(dim, idx_target); %conversion
    idx_target2 = sub2ind([dim(2), dim(1)], row, col);

    requestedTarget = [requestedTarget; idx_target2];    
end
idx_target3 = sort(requestedTarget, 'ascend'); %sort

%Update
sel_str = 'merged';
filename_req = fullfile(workingDir, strcat(sel_str, '.csv')); %for merged file

writeGeopixeRegion_Stream(change_list, {char_dim, sel_str, idx_target3}, filename_req);

fprintf('%s ready..\n', sel_str)

end