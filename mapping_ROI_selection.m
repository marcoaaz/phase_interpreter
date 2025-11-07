function [ROI_mask, pos_ROI] = mapping_ROI_selection(phasemap_rgb, tablerank2, mask_type)

%Manual box: If fixing margin artifacts has remnants, fix them manually.
%Required for avoiding RAM overload (Perseverance abration patches)
%or very long processing times (~15min)

mineral_targets = tablerank2.Mineral; %assuming same sorting
triplet2 = [tablerank2.Triplet_1, tablerank2.Triplet_2, tablerank2.Triplet_3];

hFig = figure;

imshow(phasemap_rgb, triplet2) %triplet required for discrete colorbar

%colorbar
n_masks1 = length(mineral_targets);
posTicks = (1:(n_masks1 + 1)) - 0.5;
Ticks = posTicks/n_masks1; %scaled from 0 to 1
c = colorbar('eastoutside', 'Ticks', Ticks, 'TickLabels', mineral_targets, ...
    'TickDirection', 'out', 'TickLength', 0.005, 'TickLabelInterpreter', 'none'); %include empty pixels
set(c, 'YDir', 'reverse');
c.AxisLocation = 'out';
c.FontSize = 8;
c.Label.String = 'Mineral masks';
c.Label.FontSize = 10;

%accommodate colorbar
decrease_by = 0.05; 
axpos = get(gca, 'position');
axpos(3) = axpos(3) - decrease_by;
set(gca, 'position', axpos);

if strcmp(mask_type, 'circle')
    h = drawcircle('Color', 'k', 'FaceAlpha', 0.4);
elseif strcmp(mask_type, 'rectangle')
    h = drawrectangle('Color', 'k', 'FaceAlpha', 0.4);
end

ROI_mask = createMask(h); %refine section_mask

ROI = regionprops(ROI_mask, 'BoundingBox'); %top left X, Y, W, H
ROI = ROI.BoundingBox;
tl_row = ceil(ROI(2));
tl_col = ceil(ROI(1));
br_row = tl_row + ROI(4) - 1;
br_col = tl_col + ROI(3) - 1;
pos_ROI = [tl_row, tl_col, br_row, br_col];

% close(hFig)

end