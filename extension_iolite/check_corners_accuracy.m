function check_corners_accuracy(x, y, candidate_corners, envelope_array) 

n_reach = 100; %informs about raster orientation (follow red line)
coordinates_tl = candidate_corners{1}; 
coordinates_tr = candidate_corners{2}; 
coordinates_bl = candidate_corners{3}; 
coordinates_br = candidate_corners{4};        

hFig = figure;
hFig.Position = [120, 120, 900, 900];

handle1 = plot(x(1:n_reach), y(1:n_reach), '.', 'Color', 'red');
hold on
handle2 = plot(x(n_reach+1:end), y(n_reach+1:end), '.', 'Color', 'blue');

handle3 = plot(coordinates_tl(:, 1), coordinates_tl(:, 2), '.', 'Color', 'green');
handle4 = plot(coordinates_tr(:, 1), coordinates_tr(:, 2), '.', 'Color', 'green');
handle5 = plot(coordinates_bl(:, 1), coordinates_bl(:, 2), '.', 'Color', 'green');
handle6 = plot(coordinates_br(:, 1), coordinates_br(:, 2), '.', 'Color', 'green');

handle7 = plot(envelope_array(:, 1), envelope_array(:, 2), '.', 'Color', 'magenta');

hold off
axis equal

end