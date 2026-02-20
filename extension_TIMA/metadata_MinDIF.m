function [montage_Info, table_mineral3, destinationDir] = metadata_MinDIF(experiment_path, plotOption)

%This function reads a TIMA MinDIF export XML files and obtains tile
%configuration required to reconstruct (stitching) the sample acquisition montage 

%Updated: 21-Jan-26, 13-Feb-26, Marco Acevedo

file_fields = fullfile(experiment_path, 'fields.xml');
file_measurement = fullfile(experiment_path, 'measurement.xml');
file_phases = fullfile(experiment_path, 'phases.xml');

destinationDir = fullfile(experiment_path, 'phasemap_reconstruction'); %output
if ~exist(destinationDir, 'dir')
    mkdir(destinationDir);
end 

%% Mineral info

outStruct1 = xml2struct(file_phases);
str1 = outStruct1.ExportedMeasurementPhases.PrimaryPhases.PrimaryPhase;
n_phases = length(str1);

%parsing
str2 = [str1{1, :}];
str3 = [str2.Attributes;];
table_mineral = struct2table(str3);
temp1 = table_mineral.color;
triplet = hex2rgb(temp1);
label = str2double(string(table_mineral.id));
mass = str2double(string(table_mineral.mass)); %TIMA stuff

original_names = table_mineral.name;
original_names1 = strrep(original_names, '/', '-');

table_mineral2 = table(label, original_names1, mass, ...
    triplet(:, 1), triplet(:, 2), triplet(:, 3), ...
    'VariableNames', {'Label', 'Mineral', 'Mass', ...
    'Triplet_1', 'Triplet_2', 'Triplet_3'});

table_mineral3 = sortrows(table_mineral2, "Label", "ascend");

%% Measurement info

outStruct2 = xml2struct(file_measurement);

%squared tile
str0 = outStruct2.ExportedMeasurementData.ViewField.Text; %microns
str1 = outStruct2.ExportedMeasurementData.ImageWidth.Text; %px
str2 = outStruct2.ExportedMeasurementData.ImageHeight.Text;

str5 = outStruct2.ExportedMeasurementData.SampleDef.SampleWidth.Text;
str6 = outStruct2.ExportedMeasurementData.SampleDef.SampleHeight.Text;

try
    str3 = [outStruct2.ExportedMeasurementData.SemImages.SemImage{1, :}];    
    str4 = [str3(:).FileName];
    file_tile = {str4(1).Text, str4(2).Text, 'mask.png', 'phases.tif'}; %bse, cl, mask, phases

catch %Brace indexing is not supported for variables of this type.
    str3 = [outStruct2.ExportedMeasurementData.SemImages.SemImage];
    str4 = [str3(:).FileName];
    file_tile = {str4(1).Text, 'mask.png', 'phases.tif'}; %bse, mask, phases
end

viewField = str2double(str0);
tileSize_px = str2double(str1);
pixel_calibration = viewField/tileSize_px;
sprintf('Pixel calibration = %d microns/px', pixel_calibration)

%% Montage info

outStruct3 = xml2struct(file_fields);
str1 = outStruct3.ExportedMeasurementFields.FieldDir.Text; %'fields'
str2 = [outStruct3.ExportedMeasurementFields.Fields.Field{1, :}];
str3 = struct2table([str2(:).Attributes]);

sectionNames = str3.name;
XStage = double(string(str3.x));
YStage = double(string(str3.y));
nfiles = length(sectionNames);

%Transforming coordinates (assumes translation only)
spatialResolution = pixel_calibration; %microns/px
XStage_px = ceil( XStage/spatialResolution );
YStage_px = ceil( YStage/spatialResolution );
XStage1 = 1 + max(XStage_px) - XStage_px; %inverting axis (TIMA)
YStage1 = 1 + YStage_px - min(YStage_px);  
metadata = table(str2double(sectionNames), XStage1, YStage1, ...
    'VariableNames', {'Tile', 'X', 'Y'});
metadata1 = sortrows(metadata, 'Tile', 'ascend');


%montage built
nrows = max(YStage1) + tileSize_px;
ncols = max(XStage1) + tileSize_px;
nrows_tiles = round(nrows/tileSize_px);
ncols_tiles = round(ncols/tileSize_px);
dim_tiles = [nrows_tiles, ncols_tiles];

%% Reconfiguring tiling (grid collection)

%Map tiles with artificial grid
corner_x = metadata1.X;
corner_y = metadata1.Y;

%Type: row-by-row; Order: right & down --> Desired
[referenceGrid, tiling_name] = gridNumberer(dim_tiles, 1, 1); 
all_labels = referenceGrid(:); %column-major order, left to right

%tiles without overlap (TIMA)
span_x = 0:tileSize_px:(ncols-tileSize_px+1); 
span_y = 0:tileSize_px:(nrows-tileSize_px+1);

[X_mesh, Y_mesh] = meshgrid(span_x, span_y);
all_points = double([X_mesh(:), Y_mesh(:)]); %follows matlab convention
 
oldLabel = zeros(length(all_labels), 1);
for i = 1:length(all_labels)  
    
    [D, I] = pdist2([corner_x, corner_y], all_points(i, :), 'euclidean', ...
        'Smallest', 1); %minimum value
    if D < 100 %px tolerance
        oldLabel(i) = metadata1.Tile(I);
    end    
end
mapping = [all_labels, oldLabel];

montage_Info = struct;
montage_Info.experiment_path = experiment_path;
montage_Info.metadata1 = metadata1;
montage_Info.mapping = mapping; 
montage_Info.dim = [nrows, ncols];
montage_Info.dim_tiles = dim_tiles;
montage_Info.tileSize_px = tileSize_px;

%Save montage metadata
save(fullfile(experiment_path, 'montage_Info.mat'), 'montage_Info', '-mat')

%% Optional: Plot tiled montage
if plotOption == 1    
    
    fontSize = 15;
    canvas = ones(nrows, ncols); %preallocating
    
    close all
    hFig = figure;
    ax = gca;
    
    imshow(canvas)
    for i = 1:nfiles
        hRectangle = drawrectangle(ax, ...
            'Position', [XStage1(i), YStage1(i), tileSize_px, tileSize_px], ...
            'InteractionsAllowed', 'none', 'LineWidth', 0.5, 'FaceAlpha', 0.1);
      
        hPoint = drawpoint(ax, ...
            'Position', [XStage1(i), YStage1(i)], ...
            'Color', 'r', 'Deletable', false, 'DrawingArea', 'unlimited');
        text(XStage1(i), YStage1(i), sectionNames{i}, ...
            'FontSize', fontSize, 'clipping', 'on')    
        hPoint.MarkerSize = 3;
        
    end
    xlim([-10, ncols+10])
    ylim([-10, nrows+10])
end

end