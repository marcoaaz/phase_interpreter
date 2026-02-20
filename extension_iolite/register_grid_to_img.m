function [coordinates_double, coordinates_int] = register_grid_to_img(filepath1, image_size, extent_dimensions, envelope_array)

table_xy = readtable(filepath1, 'VariableNamingRule','preserve');
x = table_xy.X;
y = table_xy.Y;

n_rows = image_size(1);
n_cols = image_size(2);

dist_x = extent_dimensions(1); 
dist_y = extent_dimensions(2);
px_x = extent_dimensions(3);
px_y = extent_dimensions(4);

%scattered grid registration

px_x_centre = (px_x*(n_cols))/(2*(dist_x + px_x)); %px coordinates
px_y_centre = (px_y*(n_rows))/(2*(dist_y + px_y));
% offset = ([px_x_centre, px_y_centre]);
offset = ([px_y_centre, px_y_centre]);

%fixed image matching points (spatial coordinates)
matchedPoints1 = [
    1, 1; %tl
    n_cols, 1; %tr
    1, n_rows; %bl
    n_cols, n_rows %br
    ]; 

centering = offset.*[
    [1, 1];
    [-1, 1];
    [1, -1];
    [-1, -1]
    ]; 

fixed_points = matchedPoints1 + centering;

%moving points matching points (real coordinates)
matchedPoints2 = envelope_array;
moving_points = matchedPoints2;

%estimate geometric transformation
tform = estgeotform2d(moving_points, fixed_points, 'affine'); 

[x_1, y_1] = transformPointsForward(tform, x, y);

coordinates_double = [x_1, y_1];
coordinates_int = ceil(coordinates_double - 0.5); %interrogation

end