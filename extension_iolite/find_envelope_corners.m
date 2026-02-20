function [envelope_array, candidate_corners] = find_envelope_corners(coordinates, corners, search_dist)

tl = corners(1, :);
tr = corners(2, :);
bl = corners(3, :);
br = corners(4, :);

%envelopping corners
[~, I1] = pdist2(coordinates, tl, 'euclidean', 'Smallest', search_dist);
[~, I2] = pdist2(coordinates, tr, 'euclidean', 'Smallest', search_dist);
[~, I3] = pdist2(coordinates, bl, 'euclidean', 'Smallest', search_dist);
[~, I4] = pdist2(coordinates, br, 'euclidean', 'Smallest', search_dist);

coordinates_tl = coordinates(I1, :);
coordinates_tr = coordinates(I2, :);
coordinates_bl = coordinates(I3, :);
coordinates_br = coordinates(I4, :);

temp1 = min(coordinates_tr, [], 1);
temp2 = max(coordinates_tr, [], 1);
temp3 = min(coordinates_bl, [], 1);
temp4 = max(coordinates_bl, [], 1);

tl_e = min(coordinates_tl, [], 1); %find envelope
tr_e = [temp2(1), temp1(2)];
bl_e = [temp3(1), temp4(2)];
br_e = max(coordinates_br, [], 1);

envelope_array = [tl_e; tr_e; bl_e; br_e];
candidate_corners = {coordinates_tl, coordinates_tr, coordinates_bl, coordinates_br};

end