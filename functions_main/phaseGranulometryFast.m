function [finer_pixels, original_pixels] = phaseGranulometryFast(map_binary, sizeMax, destinationDir)
n_masks = length(map_binary);
original_pixels = zeros(n_masks, 1);
finer_pixels = zeros(n_masks, sizeMax);

% Smallest possible SE for iterative operations
SE_step = strel('disk', 1, 0); 
tf = canUseGPU;

for i = 1:n_masks
    % Convert sparse to full ONCE per mask
    % If it fits in memory as a cell, it fits as a full matrix during processing
    subset = full(map_binary{i});
    
    if tf
        subset = gpuArray(subset);
    end

    % 1. Base treatment (Equivalent to imclose with r=0 is just the mask itself)
    % If you actually need hole filling, use imfill(subset, 'holes') instead.
    subset_base = subset; 
    original_pixels(i) = sum(subset_base, 'all');

    % 2. Iterative Granulometry
    % We use the fact that an opening of size J can be approximated 
    % by successive erosions to find which grains "disappear" at each step.
    current_erosion = subset_base;
    
    for j = 1:sizeMax
        % Successive erosion: This is much faster than recalculating 
        % imopen(base, large_SE) every loop.
        current_erosion = imerode(current_erosion, SE_step);
        
        % To get the granulometry (opening), we must redilate the eroded result
        % with the original size SE to see what's left.
        SE_j = strel('disk', j, 0);
        opened = imdilate(current_erosion, SE_j);
        
        % Count pixels coarser than radius J
        coarser_count = sum(opened, 'all');
        
        % Finer pixels = Original - Coarser
        finer_pixels(i, j) = original_pixels(i) - coarser_count;
    end
end

% Move data back from GPU once at the very end
if tf
    finer_pixels = gather(finer_pixels);
    original_pixels = gather(original_pixels);
end

% Saving (as per your original requirement)
if ~exist(destinationDir, 'dir'), mkdir(destinationDir); end
writematrix(finer_pixels, fullfile(destinationDir, 'finerPixels.csv'));
writematrix(original_pixels, fullfile(destinationDir, 'originalPixels.csv'));

end