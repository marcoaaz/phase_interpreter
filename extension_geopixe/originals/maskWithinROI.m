function [roiHandle] = maskWithinROI(roiHandle, img_size, maskPM, infoTable)
%for regionToGeoPIXE_v4.m interaction

%Input:
%roiHandle = drawn ROI
%img_size = size of image reference (equal to image stack)
%maskPM = phase map as vector;
% minerals = string with names of all original phases ranked following
% label numbers in qupathPhaseMap_v7.m

minerals = infoTable.Mineral;

n_masks = length(minerals);
logicalMask = createMask(roiHandle, img_size(1), img_size(2));
roiMineralMask = maskPM(logicalMask(:)); 

pixelPopulations = zeros(1, n_masks);
for i = 1:n_masks
    pixelPopulations(i) = sum(roiMineralMask == i);
end

%indices
indList = cell(1, n_masks);
for j = 1:n_masks
    temp_logical = find( (maskPM == j) & logicalMask(:) );
    indList{j} = temp_logical;
end

roiHandle.UserData.logicalMask = logicalMask(:);
roiHandle.UserData.roiMineralMask = roiMineralMask;
roiHandle.UserData.pixelPopulations = pixelPopulations;
roiHandle.UserData.indList = indList;

%Update
assignin('base', 'pixelPopulations', pixelPopulations);   
assignin('base', "indList", indList)

end