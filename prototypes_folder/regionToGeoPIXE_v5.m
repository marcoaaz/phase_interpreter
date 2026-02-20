
%regionToGeoPIXE_v4.m

%Script to read QuPath-Phase Interpreter output and generate Q-vectors for
%spectral analysis in GeoPIXE (new region import tool).

%Collaboration on the GeoPIXE end: Chris Ryan, Michael Jones
%Created: Dec-2023, Marco Acevedo Z.
%Updated: 19-Jul-24, 22-Jan-26, M.A.

%Note: figure flipped upside down in GeoPIXE

%only one to change
% phasemapDir = 'E:\paper 3_datasets\data_DMurphy\91714-81R5w-quartz-detail\tiff\quPath_gabbro\segmentation\11sep23_trial1'; %gabbro
% phasemapDir = 'E:\paper 3_datasets\harzburgite_synchrotron_christoph\tiff_HiRes\qupath_harzburgite\segmentation\11sep23_test4'; %harzburgite
% phasemapDir = 'E:\paper 3_datasets\conference paper_Goldschmidt\Export\registration\quPath_project\19Sep_RT_test3'; %limestone
% phasemapDir = 'C:\Users\n10832084\OneDrive - Queensland University of Technology\Desktop\Teresa_article collab\qupath_project\16-jul_test1'; %gabbro

clear 
clc

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

%User input

interactive = 'yes'; %define ROI, yes/no
phasemapDir = 'H:\Collaborations\Teresa_article collab\qupath_project\old\16-jul_test1';
requestedMinerals = {'cpx_mantle', 'cpx_rim', 'cpx_core'}; %to merge

%Script

%default
infoFile = fullfile(phasemapDir, 'species.xlsx'); %after Phase Interpreter
phasemapFile = fullfile(phasemapDir, 'phasemap_target_RGB.tif'); 
labelFile = fullfile(phasemapDir, 'phasemap_label_full.tif');
geopixe_file0 = fullfile(script_path, 'extension_geopixe', 'Marco-region0.csv'); %original GeoPIXE region to modify

workingDir = fullfile(phasemapDir, 'geopixe_Qvectors');
mkdir(workingDir)

%Input
infoTable = readtable(infoFile, 'Sheet', 'phaseMap');
imgRGB = imread(phasemapFile);
imgLabel = imread(labelFile);
n_rows = size(imgRGB, 1);
n_cols = size(imgRGB, 2); 
dim = [n_rows, n_cols];

if strcmp(interactive, 'no')
        
    [indList] = indWithinMAP_pro(imgLabel, infoTable);

    %Save Q-vectors
    geopixe_export_all(geopixe_file0, infoTable, indList, dim, workingDir)
    geopixe_export_merged(geopixe_file0, infoTable, requestedMinerals, ...
        indList, dim, workingDir)

elseif strcmp(interactive, 'yes')

    % Drawing Target pixels
    square_size = 500; 

    close all
    hFig = figure;
    
    imshow(imgRGB)
    ax = gca;
    
    initial_pos = uint16([dim(2)/2, dim(1)/2, square_size, square_size]); %edit size
    % initial_pos = [1, 1, dim(2), dim(1)] - 0.5*[1, 1, -1, -1];

    hROI = drawrectangle("Position", initial_pos, 'Parent', ax); %full area

    [hROI] = maskWithinROI_pro(hROI, dim, imgLabel(:), infoTable); %initial update
    
    addlistener(hROI, 'MovingROI', ...
        @(varargin)maskWithinROI_pro(hROI, dim, imgLabel(:), infoTable));

end

%% Interactive: Save Q-vectors

geopixe_export_all(geopixe_file0, infoTable, indList, dim, workingDir)
geopixe_export_merged(geopixe_file0, infoTable, requestedMinerals, ...
    indList, dim, workingDir)
