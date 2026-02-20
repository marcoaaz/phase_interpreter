function [img2, triplet, envelope_array, extent_dimensions, raster_orientation...
    ] = read_everything_mask(filepath1, temp_path, element_str, search_dist, plotOption)

%Colour boosting using percentiles
out2 = 0.5; %default= 0.5, for spot analysis
out1 = out2; %default= 0.5, for exported matrices from spot analysis

%LA-ICP-MS stage coordinates with compositional data
table_xy = readtable(filepath1, 'VariableNamingRule','preserve');
x = table_xy.X;
y = table_xy.Y;
coordinates = [x, y]; %43723 (mm ?)

%data for spots
element1 = table_xy{:, strcat(element_str, '_ppm')};
P = prctile(element1, [out2, 100-out2], "all");
element2 = rescale(element1, 0, 255, "InputMin", P(1), "InputMax", P(2));
element3 = uint8(element2);
cmap1 = jet(256);
triplet = squeeze(ind2rgb(element3, cmap1));

%Iolite export: data matrix after converstion from spot to img
[~, options, ~] = fileparts(temp_path);
idx = contains(options, element_str);
img = imread(temp_path{idx});
P = prctile(img, [out1, 100-out1], "all");
img2 = rescale(img, 0, 255, "InputMin", P(1), "InputMax", P(2));

%% Finding map corners (moving image)
%Describing grid assuming rastering in a comb pattern

x_prime = diff(x); %difference between adjacent elements
step_x = x_prime(2)-x_prime(1);

if step_x == 0
    raster_orientation = 'vertical';

    temp = imextendedmax(x_prime, 1);
    idx_secondLine = find(temp, 1); 
    idx_lastLine = find(temp, 1, 'last');
    
    %conventional corners
    tl = [x(1), y(1)]; %ideal
    tr = [x(idx_lastLine + 1), y(idx_lastLine + 1)];
    bl = [x(idx_secondLine), y(idx_secondLine)];    
    br = [x(end), y(end)]; %ideal    
    corners = [tl; tr; bl; br];

    [envelope_array, candidate_corners] = find_envelope_corners(coordinates, corners, search_dist);
    
    %real coordinates
    dist_x = envelope_array(2, 1) - envelope_array(1, 1); %map extend
    dist_y = envelope_array(3, 2) - envelope_array(1, 2);
    px_x = x(idx_secondLine + 1) - envelope_array(1, 1);
    px_y = y(2) - y(1); %pixel size

elseif step_x > 0
    raster_orientation = 'horizontal';
        
    temp = imextendedmin(x_prime, 1);
    idx_secondLine = find(temp, 1); %
    idx_lastLine = find(temp, 1, 'last');
    
    %spot near the corners corners (conventional raster)
    tl = [x(1), y(1)]; %ideal
    tr = [x(idx_secondLine), y(idx_secondLine)];
    bl = [x(idx_lastLine + 1), y(idx_lastLine + 1)];
    br = [x(end), y(end)]; %ideal
    corners = [tl; tr; bl; br];

    [envelope_array, candidate_corners] = find_envelope_corners(coordinates, corners, search_dist);
    
    %real coordinates
    dist_x = envelope_array(2, 1) - envelope_array(1, 1); %map extend
    dist_y = envelope_array(3, 2) - envelope_array(1, 2);
    px_x = x(2) - x(1); %pixel size
    px_y = y(idx_secondLine + 1) - envelope_array(1, 2);

end
extent_dimensions = [dist_x, dist_y, px_x, px_y];

% Quality check (enveloping points)
if plotOption == 1    
    check_corners_accuracy(x, y, candidate_corners, envelope_array) 
end

end