
%qupathPhaseMap_v13.m 

%Script to build a phase map from a QuPath project that contains a trained
%pixel classifier and the corresponding labelled (predicted) image (ome.tif
%output). It outputs a folder named after the classifier with the desired
%outputs including:

%*Phase maps and modal mineralogy (Acevedo Zamora & Kamber, 2023)
%*Multiresolution association matrices (Koch, 2017), 
%*Adjacency (or accessibility) maps (Kim et al., 2022). 

%Previous version: 'qupathPhaseMap_v10_simplified.m'

%Created: 20-Aug-24, Marco Acevedo Zamora
%Updated: 26-Nov-24, 12-Mar-25, 7-Nov-25, 11-Feb-26, M.A.

%Citation: https://doi.org/10.3390/min13020156
%Original code repository: https://github.com/marcoaaz/Acevedo-Kamber/tree/main/QuPath_generatingMaps

%Information:
%class_bg: for background, write only existing ones: {'epoxy', 'glass_polish', 'background'}
%resolution: check original input image metadata and Pixel Classifier 'Resolution' value
%sizeMax: virtual sieve for morphological operation (corresponds to plot X-axis)

close all
clear
clc
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
addpath(fullfile(scriptsMarco, 'external_package\rgb'));


%Manual User input:
rootFolder = 'H:\Collaborations\Balz-Rodrigo-Matthew collab\rodrigo work\UHP32_benchmark\registration_11-Apr-24\registered\8bit\stack\qupath trial_14-Oct-25'; %qupath project
classifierName = 'run_s10-hrMaps'; %*.ome.tif saved from QuPath
class_bg_txt = 'hole';
kernel_size = 0;
rot_angle = 90; %rotation angle (counter-clockwise)
action_mirror = 0; %horizontal flip
trial_tag = 'tag_11feb26_1';
mask_type = 'circle';
manual_names_txt = 'Ol, Cpx, Grt, Opx, Spinel'; %{'Cpx', 'Grt', 'Hole', 'Ol', 'Opx'};
selected_targets_txt = 'Opx, Grt, Cpx';
% selected_analysis = app.GenerateoutputsListBox.Value;
radius = 1; %search radius for multi-scale Association Index
connectivity = 'four';
resolution = 1; %microns/pixel for GSD and stats
sizeMax = 60; %default=60 in pixels

%User input:
% rootFolder = app.QuPathprojectEditField.Value; %qupath project
% classifierName = app.TrainedclassifierEditField.Value; %*.ome.tif saved from QuPath
% class_bg_txt = app.BackgroundclassEditField.Value; %classes to ignore, if not found (uses all)
% kernel_size = app.MaskdilationDropDown.Value;
% rot_angle = app.MaprotationDropDown.Value; %rotation angle (counter-clockwise)
% action_mirror = app.MirrorhorizontallyCheckBox.Value; %horizontal flip
% trial_tag = app.TrialtagEditField.Value;
% mask_type = app.TypeofROIDropDown.Value;
% manual_names_txt = app.RenamemineralsEditField.Value; %{'Cpx', 'Grt', 'Hole', 'Ol', 'Opx'};
% selected_targets_txt = app.RenamemineralsEditField_2.Value; %default= minerals_original
% selected_analysis = app.GenerateoutputsListBox.Value;
% radius = app.SearchradiuspxEditField.Value; %search radius for multi-scale Association Index
% connectivity = app.ConnectivityDropDown.Value;
% resolution = app.PixelcalibrationmpxEditField.Value; %microns/pixel for GSD and stats
% sizeMax = app.TopmeshpxEditField.Value; %default=60 in pixels

%% Script begins

%default
class_bg_txt1 = regexprep(class_bg_txt, '\s*', '');
class_bg = strsplit(class_bg_txt1, ',');
manual_names_txt1 = regexprep(manual_names_txt, '\s*', '');
manual_names = strsplit(manual_names_txt1, ',');
selected_targets_txt1 = regexprep(selected_targets_txt, '\s*', '');
selected_targets = strsplit(selected_targets_txt1, ',');

areaTH = 15; %px for grain measurements
suffix = '.ome.tif';
phasemap_inputName = strcat(classifierName, suffix);%default

[minerals, triplet, destinationDir] = read_qupath_metadata(phasemap_inputName, suffix, rootFolder);

[phasemap_fg, section_mask, tablerank] = read_qupath_map(phasemap_inputName, class_bg, ...
    minerals, triplet, kernel_size, destinationDir);
manual_names0 = tablerank.Mineral';

[phasemap] = transform_map(phasemap_fg, section_mask, rot_angle, action_mirror);

[tablerank1, phasemap1] = edit_phasemap(phasemap, tablerank, destinationDir);

tablerank1 = readtable(fullfile(destinationDir, 'species.xlsx'), 'Sheet', 'phaseMap');

if strcmp(manual_names, "") %GUI edition (for a script)
    manual_names = manual_names0;
end
tablerank1.Mineral = manual_names'; 

selected_targets0 = tablerank1.Mineral';
[phasemap_colour, tablerank3] = phasemap_rgb(phasemap1, tablerank1, selected_targets0, destinationDir);

plot_phasemap(phasemap_colour, tablerank3, destinationDir)

%Default ROI  
ROI_mask = ones(size(phasemap1));
pos_ROI = floor([1, 1, size(phasemap1, 1), size(phasemap1, 2)]);

% %Optional: Draw ROI  
% [ROI_mask, pos_ROI] = mapping_ROI_selection(phasemap_colour, tablerank1, mask_type);

%% Apply mask
phasemap1(~ROI_mask) = 0; 
class_map = phasemap1(pos_ROI(1):pos_ROI(3), pos_ROI(2):pos_ROI(4)); %crop

%New folder
tag_folder = fullfile(destinationDir, trial_tag);
mkdir(tag_folder)

%ROI phase map
selected_targets0 = tablerank1.Mineral';
%Generate preview
if strcmp(selected_targets, "")
    selected_targets = selected_targets0;
end
[class_map_colour, tablerank3] = phasemap_rgb(class_map, tablerank1, selected_targets, tag_folder);
manual_names0 = tablerank3.Mineral;

%Modal mineralogy
plotLogHistogramH(tablerank3, tag_folder)
plotLogHistogramH2(tablerank3, tag_folder)

%association
[~, AIM_pct, access_map] = phasemapAIM(class_map, tablerank3, radius, connectivity, tag_folder); 

plotStackedH_sorted(AIM_pct, tablerank3, manual_names0, tag_folder) %named left-to-right

%adjacency
[adjacency_map, adjacency_rgb] = adjacencyCheck(class_map, access_map, tablerank3, tag_folder);

%grain measurements
[binary, binary_totals] = binarise_map(class_map, tablerank3);
[sub_stats2] = grain_measurements(binary, tablerank3, areaTH, tag_folder);

%granulometry (grain size distribution)
[finer_pixels, original_pixels] = phaseGranulometry(binary, sizeMax, tag_folder); %px
plotGranulometry(finer_pixels, original_pixels, sizeMax, tablerank3, resolution, tag_folder) %microns
