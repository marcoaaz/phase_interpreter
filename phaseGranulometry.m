function [finer_pixels, original_pixels] = phaseGranulometry(map_binary, sizeMax, destinationDir)
% Granulometry

%gpuDevice %if you have latest versions of CUDA and GPU driver
tf = canUseGPU;

%Option: pre-treatment (structuring element SE, r>0)
SE_base = strel('disk', 0, 0); %r= radius; %n approximates a larger SE
%SE_base.Neighborhood %checks binary mtx (offset if non-flat)

n_masks = length(map_binary);
original_pixels = zeros(1, n_masks); %for storing
coarser_pixels = zeros(n_masks, sizeMax);
finer_pixels = zeros(n_masks, sizeMax);
for i = 1:n_masks
    mineral_binary = map_binary{i};

    if tf
        subset = gpuArray(mineral_binary);
    else
        subset = mineral_binary;
    end
    
    subset_base = imclose(subset, SE_base); %filling holes
    
    %morphological operation
    for j = 1:sizeMax
        SE = strel('disk', j, 0); 
        subset_opened = imopen(subset, SE); 

        coarser_pixels(i, j) = sum(gather(subset_opened), 'all');
    end

    original_pixels(i) = sum(gather(subset_base), 'all');
    finer_pixels(i, :) = original_pixels(i) - coarser_pixels(i, :);    
end

%saving
finerPixelsfile = 'finerPixels.csv'; %aprox. min elapsed time
originalPixelsfile = 'originalPixels.csv'; 
fullDest1 = fullfile(destinationDir, finerPixelsfile);
fullDest2 = fullfile(destinationDir, originalPixelsfile);
writematrix(finer_pixels, fullDest1) 
writematrix(original_pixels, fullDest2) 

end
