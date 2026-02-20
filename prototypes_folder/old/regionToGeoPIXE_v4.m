
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

scriptDir1 = 'E:\Alienware_March 22\scripts_Marco\updated MatLab scripts\quPath bridge';
addpath(scriptDir1)

phasemapDir = 'H:\Collaborations\Teresa_article collab\qupath_project\old\16-jul_test1';
datasetDescription = 'gabbro4'; %trial
interactive = 'yes'; %define ROI, yes/no
sel_str_req = 'cpx_all'; %custom merge
requestedMinerals = {'cpx_mantle', 'cpx_rim', 'cpx_core'}; %to merge

%Script

%default
geopixe_file0 = fullfile(scriptDir1, 'Marco-region0.csv'); %original GeoPIXE region to modify
workingDir = fullfile(phasemapDir, 'geopixe_Qvectors');
infoFile = fullfile(phasemapDir, 'species.xlsx'); %after Phase Interpreter
phasemapFile = fullfile(phasemapDir, 'phasemap_target_RGB.tif'); 
labelFile = fullfile(phasemapDir, 'phasemap_label_full.tif');

destDir = fullfile(workingDir, datasetDescription); 
filename_req = fullfile(destDir, strcat(datasetDescription, '_', sel_str_req, '.csv')); %for merged file
mkdir(destDir)

%Input
infoTable = readtable(infoFile, 'Sheet', 'phaseMap');
imgRGB = imread(phasemapFile);
imgLabel = imread(labelFile);
n_rows = size(imgRGB, 1);
n_cols = size(imgRGB, 2); 
pixelPopulations = infoTable.Pixels;
minerals = infoTable.Mineral;
minerals %printed info

if strcmp(interactive, 'no')
    
    [indList] = indWithinMAP(imgLabel, minerals);

    %Save Q-vectors
    geopixe_export_all(geopixe_file0, pixelPopulations, indList, minerals, n_rows, n_cols, destDir, datasetDescription)
    geopixe_export_merged(geopixe_file0, pixelPopulations, indList, minerals, requestedMinerals, n_rows, n_cols, filename_req)

elseif strcmp(interactive, 'yes')

    % Drawing Target pixels
    square_size = 500; 

    close all
    hFig = figure;
    
    imshow(imgRGB)
    ax = gca;
    
    initial_pos = uint16([n_cols/2, n_rows/2, square_size, square_size]); %edit size
    hROI = drawrectangle("Position", initial_pos, 'Parent', ax); %full area
    [hROI] = maskWithinROI(hROI, [n_rows, n_cols], imgLabel(:), minerals); %initial update
    
    addlistener(hROI, 'MovingROI', ...
        @(varargin)maskWithinROI(hROI, [n_rows, n_cols], imgLabel(:), minerals));

end

%% Interactive: Save Q-vectors
geopixe_export_all(geopixe_file0, pixelPopulations, indList, minerals, n_rows, n_cols, destDir, datasetDescription)
geopixe_export_merged(geopixe_file0, pixelPopulations, indList, minerals, requestedMinerals, n_rows, n_cols, filename_req)

