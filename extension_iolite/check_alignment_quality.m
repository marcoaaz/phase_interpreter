function check_alignment_quality(img2, coordinates_double, triplet)

x_1 = coordinates_double(:, 1);
y_1 = coordinates_double(:, 2);

%Plot
hFig = figure;
hFig.Position = [1200, 300, 1200,1200];

imshow(img2, gray(256), 'InitialMagnification', 180)
hold on

scatter(x_1, y_1, 25, triplet, 'filled', 'MarkerFaceAlpha', 0.5)

%n_reach = 1000; %to visualise top left corner
% scatter(x_1(1:n_reach), y_1(1:n_reach), 15, 'yellow')

hold off

end