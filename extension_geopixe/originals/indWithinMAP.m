function [indList] = indWithinMAP(imgLabel0, infoTable)
%assumes: imgLabel follows ranked population within infoTable

minerals = infoTable.Mineral;
mineral_labels = infoTable.NewLabel;
n_masks = length(minerals);

img_size = size(imgLabel0);
logicalMask = true(img_size);

imgLabel = imgLabel0(:);

%indices
indList = cell(1, n_masks);
for j = 1:n_masks
    sprintf('processing %d ..', minerals{j});

    temp_logical = find( (imgLabel == mineral_labels(j)) & logicalMask(:) );
    
    indList{j} = temp_logical;
end

end