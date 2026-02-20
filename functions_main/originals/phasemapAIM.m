
function [AIM, AIM_pct, access_map] = phasemapAIM(map, tablerank3, r, connectivity, destinationDir)
% Multiscale Association Index Matrix (following Koch, 2017)

%Note: subsetting causes problems (future work)
%[AIM, AIM_pct, access_map] = phasemapAIM(class_map(1500:2000, 1500:2000), 1, 'four', destinationDir); %15 min

%define variables
label_list = tablerank3.NewLabel; %unique(map);
foreground_list = (label_list ~= 0);
n_masks = sum(foreground_list);
phase = label_list(foreground_list)';

%define connectivity (radius search)
diameter = 2*r + 1; %1 px for the outer halves
switch connectivity
    case 'four' %4-connectivity
        conn_four = zeros(diameter); 
        conn_four(:, r+1) = 1;
        conn_four(r+1, :) = 1; 
        connectivity_sel = conn_four;
    case 'eight' %8-connectivity (optional)
        conn_eight = ones(diameter); 
        connectivity_sel = conn_eight;
end

map_rollout = double(map(:, :)); %search path requirement (line 43)
rows = size(map_rollout, 1);
cols = size(map_rollout, 2);

%skip fringes (alternative: padding)
from_r = 1 + r;
to_r = rows -r;
from_c = 1 + r;
to_c = cols -r;

%pre-allocate accessibility maps
access_map = cell(n_masks, n_masks);
for ii = 1:n_masks
    for jj = 1:n_masks
        access_map{ii, jj} = zeros(rows, cols);
    end
end

frequency = zeros(n_masks, n_masks);
for j = from_c:to_c %columns-major order
    for i = from_r:to_r 
        %Search patch
        tl_r = i-r; 
        tl_c = j-r;
        br_r = i+r; 
        br_c = j+r;
        searchMatrix = map_rollout(tl_r:br_r, tl_c:br_c);
        searchMatrix = searchMatrix.*connectivity_sel;

        %searching       
        m = searchMatrix(r+1, r+1); %get centre (target mineral)
        row_num = find(phase == m); %all ranked; clear value        

        condition1 = (m == 0);
        condition2 = isempty(row_num); %not in FoV

        if condition1 | condition2  %skip background (NaN pixels)
            continue
        else
            
            col_num = 0; %clear value
            searchMatrix(r+1, r+1) = 0; %replacing center by 0

            for k = phase
                col_num = col_num + 1;
                logical = searchMatrix == k;                            
                counts = sum(logical, 'all');

                %Association indicator matrix (AIM) in 2D after Koch (2017) following Lund (2013)
                frequency(row_num, col_num) = frequency(row_num, col_num) + counts;
                
                %Adjacency maps after Peters, C.A., & Kim, J.J. (2020)
                if counts > 0 
                    access_map{row_num, col_num}(i, j) = m;
                end
            end 
            
        end
    end
end
frequency_sum = sum(frequency, 'all');%subtotal for each centroid
AIM = (1/frequency_sum)*frequency;

AIM_woD = AIM - (tril(AIM) - tril(AIM, -1)); %without diagonal
[rows, ~] = size(AIM_woD);
AIM_sum = sum(AIM_woD, 1); %adding rows
denom = repmat(AIM_sum, [rows, 1]); %replicate vertically
AIM_pct = 100*AIM_woD ./ denom;
AIM_pct(denom==0) = 0; %fix Inf (denom == 0) to 0

%saving
AIMfile = 'AIM.csv'; %aprox. 15 min elapsed time
AIMpctFile = 'AIM_pct.csv'; %mineral names in same order as species.xlsx
fullDest1 = fullfile(destinationDir, AIMfile);
fullDest2 = fullfile(destinationDir, AIMpctFile);
writematrix(AIM, fullDest1) 
writematrix(AIM_pct, fullDest2) 

%save cell with matrices/images
save(fullfile(destinationDir, 'acces_map.mat'), "access_map", '-v7.3') %>2GB file

end