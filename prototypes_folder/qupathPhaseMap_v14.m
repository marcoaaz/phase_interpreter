
%Script to build a phase map from a QuPath project that contains a trained
%pixel classifier and the corresponding labelled (predicted) image (ome.tif
%output). It outputs a folder named after the classifier with the desired
%outputs including:

%*Phase maps and modal mineralogy (Acevedo Zamora & Kamber, 2023)
%*Multiresolution association matrices (Koch, 2017), 
%*Adjacency (or accessibility) maps (Kim et al., 2022). 

%Previous version: 'qupathPhaseMap_v13.m'

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
addpath(fullfile(script_path, "saveastiff_4.5"));
addpath(fullfile(script_path, "prototypes_folder"));
addpath(fullfile(scriptsMarco, 'bfmatlab'));
addpath(fullfile(scriptsMarco, 'external_package'));
addpath(fullfile(scriptsMarco, 'external_package\rgb'));

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

% input_files = 'C:\Users\acevedoz\OneDrive - Queensland University of Technology\Desktop\slides_processing\qupath_project\test4.ome.tif';
% input_type = 'qupath';

%Manual User input:
input_files = 'H:\Collaborations\Murphy_Collaboration\TIMA_midDIF_and_checkup_10-aug-24\cb7798a9-5ba3-4dac-a8a9-ff52295d534f';
input_type = 'tima';
class_bg_txt = 'hole'; %'[Unclassified]'
kernel_size = 0;
rot_angle = 90; %rotation angle (counter-clockwise)
action_mirror = 0; %horizontal flip

trial_tag = 'tag_1';
mask_type = 'free_hand'; %rectangle, circle, free_hand, polygon
manual_names_txt = ""; %'Ol, Cpx, Grt, Opx, Spinel'
selected_targets_txt = ""; %'Opx, Grt, Cpx'
sorting_type = "ranked"; %selected, non-zero, ranked
% selected_analysis = app.GenerateoutputsListBox.Value;
radius = 1; %search radius for multi-scale Association Index
connectivity = 'four';
resolution = 1; %microns/pixel for GSD and stats
sizeMax = 60; %in microns


%% Script begins

%default
class_bg_txt1 = regexprep(class_bg_txt, '\s*', '');
class_bg = strsplit(class_bg_txt1, ',');
manual_names_txt1 = regexprep(manual_names_txt, '\s*', '');
manual_names = strsplit(manual_names_txt1, ',');
selected_targets_txt1 = regexprep(selected_targets_txt, '\s*', '');
selected_targets = strsplit(selected_targets_txt1, ',');
areaTH = 15; %px for grain measurements
sizeMax_px = floor(sizeMax/resolution); %default=60 px

tag_folder = fullfile(destinationDir, trial_tag);
mkdir(tag_folder)

%read maps
if strcmp(input_type, 'qupath')
    [rootFolder, classifierName0, ~] = fileparts(input_files);
    classifierName = strrep(classifierName0, '.ome', '');
    
    [minerals, triplet, destinationDir] = read_qupath_metadata(classifierName, rootFolder);
    [phasemap_fg, section_mask, tablerank] = read_qupath_map(classifierName, class_bg, ...
        minerals, triplet, kernel_size, destinationDir);

elseif strcmp(input_type, 'tima')
    plotOption = 0;
    [montage_Info, table_mineral2, destinationDir] = metadata_MinDIF(input_files, plotOption);
    
    [phasemap_fg, section_mask, tablerank] = read_MinDIF_map(montage_Info, table_mineral2,...
        class_bg, kernel_size);

end

winopen(destinationDir)
manual_names0 = tablerank.Mineral';

[phasemap, section_mask1] = transform_map(phasemap_fg, section_mask, rot_angle, action_mirror);
imwrite(section_mask1, fullfile(destinationDir, 'sectionMask.tif')); %explains selection

[tablerank1, phasemap1] = edit_phasemap(phasemap, tablerank, destinationDir);

%Generate preview
tablerank1 = readtable(fullfile(destinationDir, 'species.xlsx'), 'Sheet', 'phaseMap');

if strcmp(manual_names, "") %GUI edition (for a script)
    manual_names = manual_names0;
end
tablerank1.Mineral = manual_names'; 

[phasemap_colour, tablerank2] = phasemap_rgb(phasemap1, tablerank1, "", ...
    "selection", destinationDir);

plot_phasemap(phasemap_colour, tablerank2, destinationDir)

%Default ROI  
ROI_mask = true(size(phasemap1));
pos_ROI = floor([1, 1, size(phasemap1, 1), size(phasemap1, 2)]);

%% Optional: Draw ROI  
close all
% [ROI_mask, pos_ROI] = mapping_ROI_selection(phasemap_colour, tablerank2, mask_type);
[label_map, ROI_data] = mapping_ROI_manager6(phasemap_colour, destinationDir);


%% Apply mask
close all

phasemap1(~ROI_mask) = 0; 
class_map = phasemap1(pos_ROI(1):pos_ROI(3), pos_ROI(2):pos_ROI(4)); %crop

imwrite(ROI_mask, fullfile(tag_folder, 'roiMask.tif')); %explains selection (>4GB writing issue)
% options.color     = false;
% options.compress  = 'no';
% options.message   = true;
% options.append    = false;
% options.overwrite = true;
% options.big       = false;
% Z_index = 255*single(ROI_mask);
% saveastiff(uint8(Z_index), fullfile(tag_folder, 'roiMask.tif'), options);

%% ROI section

%ROI phase map
[class_map_colour, tablerank3] = phasemap_rgb(class_map, tablerank1, selected_targets, ...
    sorting_type, tag_folder);
manual_names0 = tablerank3.Mineral;

writetable(tablerank3, fullfile(destinationDir, 'species_ROI.xlsx'), 'Sheet', 'phaseMap');     

%Modal mineralogy
plotLogHistogramH(tablerank3, tag_folder)
plotLogHistogramH2(tablerank3, tag_folder)

%Mineral association
[~, AIM_pct, access_map] = phasemapAIM_fast(class_map, tablerank3, radius, connectivity, tag_folder);

plotStackedH_sorted(AIM_pct, tablerank3, manual_names0, tag_folder) %named left-to-right

%Adjacency
[adjacency_map] = adjacencyCheck_fast(class_map, access_map, tablerank3, tag_folder);

[binary, ~] = binarise_map(class_map, tablerank3);

%Mineral grain measurements (250 seconds for 11520x18944 px)
[sub_stats2] = grain_measurements_RAM(binary, tablerank3, areaTH, tag_folder);

%Granulometry (GSD - grain size distribution)
[finer_pixels, original_pixels] = phaseGranulometryFast(binary, sizeMax_px, tag_folder); %px

plotGranulometry(finer_pixels, original_pixels, sizeMax_px, tablerank3, resolution, tag_folder) %microns

%% Send ROI to GeoPIXE

geopixeDir = fullfile(tag_folder, 'geopixe_Qvectors');
mkdir(geopixeDir)

[~, tablerank3] = phasemap_rgb(phasemap1, tablerank1, selected_targets, ...
    'ranked', geopixeDir);
imgLabel = imread(fullfile(geopixeDir, 'phasemap_target.tif'));
dim = size(imgLabel);
requestedMinerals = {'Cpx', 'Opx'};

%Save Q-vectors
[indList] = indWithinMAP_pro(imgLabel, tablerank3);
geopixe_export_all(tablerank3, indList, dim, geopixeDir)
geopixe_export_merged(tablerank3, requestedMinerals, indList, dim, geopixeDir)



