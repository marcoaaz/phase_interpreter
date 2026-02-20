%'phasemap_groundtruth.m'

%Script to compare modal estimates between several phase maps of the same
%area made with 'qupathPhaseMap_v10_simplified.m'.

%Requested by reviewer 1 of Minerals manuscript. 

%Created: 11-Mar-25, Marco Acevedo
%Updated: 

%%

%assumes all phase maps: 
%Are in the same directory (same QuPath project)
%Share consistent 'species.xlsx'
%ground-truth phase map first in the list

sourceDir = 'E:\Alienware_March 22\current work\rodrigo work\UHP32_benchmark\registration_11-Apr-24\registered\8bit\stack\qupath trial';
folder_list = {
    'run_s10-hrMaps',...
    'run_s7-hrMaps',...
    'run_s7-dotMaps'
    };


%info
file2 = fullfile(sourceDir, folder_list{1}, 'species.xlsx');
table_labels = readtable(file2);
valueset = table_labels.Label;
catnames0 = table_labels.Mineral

%loop
n_maps = length(folder_list);
map_vectors = cell(1, n_maps);
for i = 1:n_maps

    file1 = fullfile(sourceDir, folder_list{i}, 'phasemap_label_full.tif');
    file2 = fullfile(sourceDir, folder_list{i}, 'species.xlsx');

    img = imread(file1);
    table_labels = readtable(file2);
    labels = table_labels.Label; %original (without population ranking)
    new_labels = table_labels.NewLabel;
    n_labels = length(new_labels);

    img1 = zeros(size(img));
    for j = 1:n_labels
        idx = (img == new_labels(j));
        img1(idx) = labels(j);

    end
    img2 = reshape(img1, [], 1);
    map_vectors{1, i} = img2;
end
map_vectors1 = horzcat(map_vectors{:});

%variable mapping
% catnames = {'Ol', 'Cpx', 'Grt', 'Opx', 'Hole', 'Spinel'}; %'Spinel'
catnames = {'Ol', 'Cpx', 'Grt', 'Opx', 'Hole', 'Grt'};
map_vectors2 = categorical(map_vectors1, valueset, catnames, Ordinal=true);

%%
sel = 2;

% names_LtoR = {'clinopyroxene', 'garnet', 'orthopyroxene', 'olivine', 'mineral1', 'hole'};
names_LtoR = {'Cpx', 'Grt', 'Opx', 'Ol', 'Hole'}; %'Spinel', 

experiment = folder_list{sel};
sprintf('Experiment_%s', experiment)

close all

cm = confusionchart(map_vectors2(:, 1), map_vectors2(:, sel));
sortClasses(cm, names_LtoR)
cm.Normalization = 'row-normalized'; 
cm.FontSize = 12;
title('Normalised confusion matrix (true positive rate)')
