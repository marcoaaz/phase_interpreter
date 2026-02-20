
%'read_LAicpMS_mtx_v5.m'

%This script reads a series of Iolite v4 chemical element matrices (export
%1), converts them into images (tiff, float32). Then, it loads 'everything'
%masks (export 2) and register the spot coordinates (X, Y) with the images
%(reprocessed export 1).

%In the second part of the script, we require importing the QuPath phase
%map for label interrogation (under each pixel/spot) and saving the
%corresponding tables to import to Iolite (X, Y, label).

%X-Y spots are exported from the entire map using an ‘everything’ mask
%that allows Iolite to assign a segmentation label at maximum resolution.
%In Iolite, the spot size (e.g., ‘slid’ width/height=20 microns) determines
%the distance_search (after the Joe Petrus emails on  iolite’s python API)
%See 22-Aug-25 (script) and 29-Aug-24 (future work DRS script).

%Created: 20-Aug-24, Marco Acevedo
%Updated: 26-Sep-24, 22-Jan-26, M.A.

%Limitations: 
% The process of identifying the map corners for registering the
%LA-ICP-MS point grids to the images requires 4 matching pairs to estimate
%the geometric transform. The current version supports a point sequence
%oriented row-wise (comb pattern), not column-wise.

%Notes:

%Everything mask = Laser stage coordinates with compositional data covering
%the entire map. The most colorful element could be used for the alignment
%quality check (best Mn55, Zr90, Mg24, Fe57, U238)

%Dave Chew: you generally get better maps the more rows you have, so if you
%had a prismatic mineral orientated E-W on a thin section, you might make
%the rasters run N-S (email 4-Oct-24)

%workingDir = 'F:\Murphy_Collaboration\Datasets_25-Sep-24\Durango apatite_Chew';
%element_str = 'Y89'; %fixed image (sample dependant)

%%
clear
clc

scriptDir1 = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\quPath bridge';
addpath(scriptDir1)
addpath(fullfile(scriptDir1, "saveastiff_4.5"))

%User input
workingDir = 'C:\Users\acevedoz\OneDrive - Queensland University of Technology\Desktop\Madagascar apatite_Chew'; %Iolite export directory
element_str = 'Pb206'; %fixed image (sample dependant)
segmentationDir = 'F:\Murphy_Collaboration\Datasets_25-Sep-24\Durango apatite_Chew\float32\30-Sep-24_trial1_linear\segmentation1\30-sep_trial1_RT'; %qupath phase map folder
desired = strcat( ...
    'apatite_', ...
    {'zone1', 'zone2', 'zone4', 'zone5', 'zone6', 'zone7'}); %selected masks (feedback)

%% Script

%Default
workingDir1 = fullfile(workingDir, 'regions/'); %export 1, Iolite v4 default
table_temp = struct2table(dir(fullfile(workingDir1, '*.xlsx'))); %find everything file
filepath1 = fullfile(table_temp.folder, table_temp.name); 
search_dist = 50; %envelopping corners

[temp_path, image_size] = floatMatrix_to_tiff(workingDir); %export 2 (xlsx), save images

[img2, triplet, envelope_array, extent_dimensions, raster_orientation] = read_everything_mask(filepath1, ...
    temp_path, element_str, search_dist, 1);

[coordinates_double, coordinates_int] = register_grid_to_img(filepath1, ...
    image_size, extent_dimensions, envelope_array);

check_alignment_quality(img2, coordinates_double, triplet)

%% Pre-requirement: Dimensionality reduction in Chemistry simplifier and Segmentation in QuPath project

[masks2] = interrogate_qupath_labelMap(filepath1, segmentationDir, desired, coordinates_int);

