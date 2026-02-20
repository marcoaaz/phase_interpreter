function plot_phasemap(PM_RGB, tablerank2, destinationDir)

mineral_targets = tablerank2.Mineral; %assuming same sorting
triplet2 = [tablerank2.Triplet_1, tablerank2.Triplet_2, tablerank2.Triplet_3];

hFig = figure;

imshow(PM_RGB, triplet2) %required for discrete colorbar

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

%save figure window
figure_frame = getframe(gcf);
fulldest = fullfile(destinationDir, 'phasemap_target_legend.tif'); 
imwrite(figure_frame.cdata, fulldest, 'Compression', 'none');

end