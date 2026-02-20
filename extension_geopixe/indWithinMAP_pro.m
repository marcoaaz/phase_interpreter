function [indList] = indWithinMAP_pro(imgLabel0, infoTable)

% 1. Extract labels and prepare
minerals = infoTable.Mineral;
mineral_labels = infoTable.NewLabel;
n_masks = length(mineral_labels);
imgLabel = imgLabel0(:);

% 2. Get indices of all non-zero pixels
% (Assuming 0 is background; if not, just use all_idx = (1:numel(imgLabel))')
all_idx = find(imgLabel > 0);
active_labels = imgLabel(all_idx);

% 3. The "Magic" Step: Group indices by their label value
% accumarray takes (key, value) pairs and groups them.
% We group 'all_idx' using 'active_labels' as the key.
indList_raw = accumarray(active_labels, all_idx, [max(mineral_labels), 1], @(x) {x});

% 4. Align with infoTable
% accumarray might return more groups than infoTable has minerals, 
% so we map them back to your specific mineral_labels order.
indList = cell(1, n_masks);
for j = 1:n_masks
    label = mineral_labels(j);
    fprintf('processing %s ..\n', minerals{j});

    if label <= length(indList_raw)
        indList{j} = indList_raw{label};
    else
        indList{j} = uint32([]); % Empty if label not found
    end
end

end