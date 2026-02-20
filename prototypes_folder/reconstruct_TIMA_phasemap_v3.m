%reconstruct_TIMA_phasemap.m

% Script that reads a TESCAN Mineralogy Data Interchange Format (MinDIF) 
% project export to reconstruct a phase map montage (liberation analysis). 
% The phase mapping in the second part of the script follows 'qupathPhaseMap_v8.m'.

% This version automatically obtains the montage metadata from the input folder.
% The 'data.sqlite3' file is the MinDIF folder header is (TIMA 2.11.0 build 2439). 

%Created: 20-Aug-24, Marco Acevedo
%Updated: 8-Jan-25, 21-Jan-26, M.A.

clear 
clc
close all
format compact %displaying list

%Dependencies
scriptsMarco = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\';            
script_path = fullfile(scriptsMarco, 'quPath bridge');

addpath(script_path);
addpath(fullfile(script_path, 'functions_main'));
addpath(fullfile(script_path, 'functions_plot'));
addpath(fullfile(script_path, 'extension_TIMA'));
addpath(fullfile(script_path, 'extension_iolite'));
addpath(fullfile(script_path, 'extension_geopixe'));
addpath(fullfile(scriptsMarco, 'bfmatlab'));
addpath(fullfile(scriptsMarco, 'external_package'));
addpath(fullfile(scriptsMarco, 'external_package\rgb'));

%experiment_path = 'D:\data_Emma\TIMA_bkup and processing\minDIF_processing\7802893c-1432-4859-8305-db91b3f2d863';
% pixel_calibration = 3
%% User input

%folder with acquisition minDIF exports
experiment_path = 'H:\Collaborations\Murphy_Collaboration\TIMA_midDIF_and_checkup_10-aug-24\cb7798a9-5ba3-4dac-a8a9-ff52295d534f';
plotOption = 0;
% class_bg = 

class_bg_txt = '[Unclassified]';
kernel_size = 0;
rot_angle = 90; %rotation angle (counter-clockwise)
action_mirror = 0; %horizontal flip
trial_tag = 'tag_ranked';
mask_type = 'circle';
manual_names_txt = ''; %'Ol, Cpx, Grt, Opx, Spinel'
selected_targets_txt = ''; %'Opx, Grt, Cpx'
% selected_analysis = app.GenerateoutputsListBox.Value;
radius = 1; %search radius for multi-scale Association Index
connectivity = 'four';
resolution = 1; %microns/pixel for GSD and stats
sizeMax = 60; %default=60 in pixels

%default
class_bg_txt1 = regexprep(class_bg_txt, '\s*', '');
class_bg = strsplit(class_bg_txt1, ',');
manual_names_txt1 = regexprep(manual_names_txt, '\s*', '');
manual_names = strsplit(manual_names_txt1, ',');
selected_targets_txt1 = regexprep(selected_targets_txt, '\s*', '');
selected_targets = strsplit(selected_targets_txt1, ',');

areaTH = 15; %px for grain measurements
suffix = '.ome.tif';

% Script

[montage_Info, table_mineral2, destinationDir] = metadata_MinDIF(experiment_path, plotOption);
[phasemap_fg, section_mask, tablerank] = read_MinDIF_map(montage_Info, table_mineral2,...
    class_bg, kernel_size);

%% Phase interpreter 

manual_names0 = tablerank.Mineral';

[phasemap] = transform_map(phasemap_fg, section_mask, rot_angle, action_mirror);

[tablerank1, phasemap1] = edit_phasemap(phasemap, tablerank, destinationDir);

tablerank1 = readtable(fullfile(destinationDir, 'species.xlsx'), 'Sheet', 'phaseMap');

if strcmp(manual_names, "") %GUI edition (for a script)
    manual_names = manual_names0;
end
tablerank1.Mineral = manual_names'; 

[phasemap_colour, tablerank3] = phasemap_rgb(phasemap1, tablerank1, "", ...
    "selected", destinationDir);

plot_phasemap(phasemap_colour, tablerank3, destinationDir)

%%
%Default ROI  
ROI_mask = ones(size(phasemap1));
pos_ROI = floor([1, 1, size(phasemap1, 1), size(phasemap1, 2)]);

%Optional: Draw ROI  
[ROI_mask, pos_ROI] = mapping_ROI_selection(phasemap_colour, tablerank1, mask_type);

%% Apply mask
close all

phasemap1(~ROI_mask) = 0; 
class_map = phasemap1(pos_ROI(1):pos_ROI(3), pos_ROI(2):pos_ROI(4)); %crop

%New folder
tag_folder = fullfile(destinationDir, trial_tag);
mkdir(tag_folder)

%ROI phase map
[class_map_colour, tablerank3] = phasemap_rgb(class_map, tablerank1, selected_targets, ...
    "ranked", tag_folder);
manual_names0 = tablerank3.Mineral;

%Modal mineralogy
plotLogHistogramH(tablerank3, tag_folder)
plotLogHistogramH2(tablerank3, tag_folder)

%association
[~, AIM_pct, access_map] = phasemapAIM(class_map, tablerank3, radius, connectivity, tag_folder); 

plotStackedH_sorted(AIM_pct, tablerank3, manual_names0, tag_folder) %named left-to-right
%%
%adjacency
[adjacency_map, adjacency_rgb] = adjacencyCheck(class_map, access_map, tablerank3, tag_folder);

%grain measurements
[binary, binary_totals] = binarise_map(class_map, tablerank3);
[sub_stats2] = grain_measurements(binary, tablerank3, areaTH, tag_folder);

%granulometry (grain size distribution)
[finer_pixels, original_pixels] = phaseGranulometry(binary, sizeMax, tag_folder); %px
plotGranulometry(finer_pixels, original_pixels, sizeMax, tablerank3, resolution, tag_folder) %microns
