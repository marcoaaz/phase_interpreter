function [roiHandle] = maskWithinROI_pro(roiHandle, img_size, maskPM, infoTable)
    % 1. Extract mineral labels from table
    % Assuming your table has 'NewLabel' or similar; if not, 1:n_masks is used.
    mineral_labels = infoTable.NewLabel; 
    n_masks = length(mineral_labels);
    
    % 2. Create the ROI mask and get its global linear indices
    % logicalMask is 218MB, so we immediately find the 'true' indices
    logicalMask = createMask(roiHandle, img_size(1), img_size(2));
    roi_global_indices = find(logicalMask); 
    
    % 3. Extract the mineral values only for the ROI
    % Instead of 218M elements, this is only [Area of ROI] elements
    roiMineralMask = maskPM(roi_global_indices); 
    
    % 4. The accumarray "Magic" (One-pass grouping and counting)
    % This groups the global indices by the mineral label found at that spot.
    % We set the size to [max(mineral_labels), 1] to ensure all labels fit.
    max_label = max(mineral_labels);
    indList_raw = accumarray(roiMineralMask, roi_global_indices, [max_label, 1], @(x) {x});
    
    % 5. Map the results back to the order of your infoTable
    indList = cell(1, n_masks);
    pixelPopulations = zeros(1, n_masks);
    
    for j = 1:n_masks
        target_label = mineral_labels(j);
        if target_label <= max_label && ~isempty(indList_raw{target_label})
            % These are already the global image indices
            indList{j} = indList_raw{target_label};
            pixelPopulations(j) = numel(indList{j});
        else
            indList{j} = []; % No pixels of this mineral in the ROI
            pixelPopulations(j) = 0;
        end
    end

    % 6. Update ROI Handle and Workspace
    
    % Note: Storing logicalMask(:) is huge. Consider if you really need it,
    % or if roi_global_indices (the sparse version) is enough.
    % roiHandle.UserData.logicalMask = logicalMask(:);
    % roiHandle.UserData.roiMineralMask = roiMineralMask;    

    assignin('base', 'pixelPopulations', pixelPopulations);   
    assignin('base', 'indList', indList);
end