function [minerals, triplet, destinationDir] = read_qupath_metadata(classifierName, rootFolder)
%Script documentation:
%Obtaining original colouring: 
%https://levelup.gitconnected.com/how-to-convert-argb-integer-into-rgba-tuple-in-python-eeb851d65a88

suffix = '.ome.tif';
phasemap_inputName = strcat(classifierName, suffix);%default

%Intermediate file names
sampleName = strrep(phasemap_inputName, suffix, '');
destinationDir = fullfile(rootFolder, sampleName);
fileName1 = fullfile(destinationDir, 'classifier_metadata.xlsx');

if ~exist(destinationDir, 'dir')
    mkdir(destinationDir);
end 

%Importing project metadata
classifierFile = strrep(phasemap_inputName, '.ome.tif', '.json');
classifierFolder = fullfile(rootFolder, 'classifiers', 'pixel_classifiers');
classifier_path = fullfile(classifierFolder, classifierFile);
% addpath(classifierFolder)

%model input
S = fileread(classifier_path); %Parse classifier metadata
outStruct = jsondecode(S);
inputChannels = struct2cell(outStruct.op.colorTransforms);
channelList = join(string(inputChannels), ', ');
n_channels = outStruct.metadata.inputNumChannels;
inputResolution = outStruct.metadata.inputResolution.pixelHeight.value; %x=y
tileWidth = outStruct.metadata.inputWidth; %x=y
pixelType = outStruct.op.op.ops{3, 1}.pixelType;

%feature maps
featureList = outStruct.op.op.ops{1, 1}.ops{1, 1}.ops.features;
featureList = join(string(featureList), ', ');

%expert annotations (name, colorRGB)
outputClassificationLabels = outStruct.metadata.outputChannels;
temp_table = struct2table(outputClassificationLabels);

%machine learning model
classifierType = outStruct.pixel_classifier_type;
trainedClassifier = outStruct.op.op.ops{2, 1}.model.class;

switch trainedClassifier
    case 'RTrees'
        %RT
        param_A = outStruct.op.op.ops{2, 1}.model.statmodel.opencv_ml_rtrees.ntrees; %n_trees        
        param_B = outStruct.op.op.ops{2, 1}.model.statmodel.opencv_ml_rtrees.training_params.max_depth; %max_depth
        outputLabels = outStruct.op.op.ops{2, 1}.model.statmodel.opencv_ml_rtrees.class_labels;

    case 'ANN_MLP'
        %ANN
        param_A = outStruct.op.op.ops{2, 1}.model.statmodel.opencv_ml_ann_mlp.layer_sizes; %layerSizes
        param_A = join(string(param_A), ', ');
        param_B = outStruct.op.op.ops{2, 1}.model.statmodel.opencv_ml_ann_mlp.training_params.term_criteria.epsilon; %epsilon
        outputLabels = num2str([1:size(temp_table, 1)]' - 1); %not available in ANN
end
temp_table1 = addvars(temp_table, outputLabels, 'NewVariableNames', 'label'); %metadata

%QuPath classifier description
summary_items = ["number of channels", 'channel names', 'resolution', 'tile width', 'bit depth', 'filters', ...
    'classifier type', 'classifier name', '# trees/layerSizes', 'maxDepth/epsilon']'; %initial "" avoids character conversion
array_items = [n_channels, channelList, inputResolution, tileWidth, pixelType, featureList, ...
    classifierType, trainedClassifier, param_A, param_B]';
summary_table = table(summary_items, array_items, 'VariableNames', {'Item', 'Value'});

dataType = 'int32';
a = int32(temp_table1.color);
B = bitand(a, 255, dataType);
G = bitand(bitsrl(a, 8), 255, dataType);
R = bitand(bitsrl(a, 16), 255, dataType);
alpha = bitand(bitsrl(a, 24), 255, dataType);
rgb_append = double([R, G, B, alpha]);
rgb_append = array2table(rgb_append);
rgb_append.Properties.VariableNames = {'R', 'G', 'B', 'alpha'};

label_table = horzcat(temp_table1, rgb_append);
minerals = label_table.name;
triplet = [label_table.R, label_table.G, label_table.B]/255;

%Save classifier metadata
writetable(label_table, fileName1, 'Sheet', 'Labels', 'WriteMode', 'overwritesheet')
writetable(summary_table, fileName1, 'Sheet', 'Summary', 'WriteMode', 'overwritesheet')

%Print info
options = table(minerals, 'VariableNames', {'Categories within QuPath map'}, 'RowNames', string(1:length(minerals)));
disp(options);

end