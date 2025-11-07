%% Root folder (channels)

rootFolder = 'D:\Acer Marco D\Geology\03-TCD\01-Project\06.1-Image processing\4-quPath murray brook\quPath phasemaps\';
cd(rootFolder);

scriptsFolder = 'C:\Users\Acer\Desktop\updated MatLab scripts\';
addpath(scriptsFolder);
addpath 'C:\Users\Acer\Desktop\updated MatLab scripts\bfmatlab'

%% Importing

quPathRGB = readtable('quPathRGB.csv');
dbRGB = readtable('color&density.csv');

ssds = spreadsheetDatastore(rootFolder, 'FileExtensions', {'.xlsx'}, ...
    'IncludeSubfolders', true); %get species.xlsx tables
ssds.ReadSize = 'file'; %one spreadsheet at a time

%Available file names
filesAvailable = ssds.Files;
n_files = length(filesAvailable);
endout = regexp(filesAvailable, filesep, 'split');
sectionNames = cell(length(endout), 1);
for m = 1:length(endout)
    sectionNames{m} = endout{m}{end-1}; %focus on folder name
end 

%% Accumulating results

reset(ssds)
accumulatorTable = table('Size', [1, 2], 'VariableTypes', {'string', 'double'}, ...
    'VariableNames', {'Mineral', 'Free'}); %pre-allocating
for i = 1:n_files
    
    temp_table = read(ssds);
    temp_table1 = temp_table(:, {'Mineral', 'Pixels'});
    temp_header = temp_table1.Properties.VariableNames;
    temp_header{2} = sectionNames{i};
    temp_table1.Properties.VariableNames = temp_header;
    temp_table1.Mineral = string(temp_table1.Mineral); %making compatible
    
    accumulatorTable = outerjoin(accumulatorTable, temp_table1, 'MergeKeys', 1);    
end
accumulatorTable(end, :) = [];
accumulatorTable(:, {'Free'}) = [];

temp_matrix = accumulatorTable{:, 2:end}'; %transpose
temp_matrix(isnan(temp_matrix)) = 0; %replace NaN with 0
columnNames = accumulatorTable.Mineral; 

%Ranking columns and sorting
totals = sum(temp_matrix, 1);
[~, index_sort] = sort(totals, 'ascend'); %most abundant on the right
mineral_labels = columnNames(index_sort);
temp_matrix = temp_matrix(:, index_sort);
totals_col = sum(temp_matrix, 2);
pct_matrix = 100*temp_matrix./totals_col;

%Sort by section/sample name
q0 = regexp(sectionNames,'\d*', 'match'); 
q1 = str2double(cat(1,q0{:}));
[~, ii] = sortrows(q1, 1);
sectionNames_sorted = sectionNames(ii); %cell

sortingVector = zeros(1, length(sectionNames));
for i = 1:length(sectionNames)
    index = strcmp(sectionNames, sectionNames_sorted{i}); %str
    sortingVector(i) = find(index);
end
pct_matrix1 = pct_matrix(sortingVector, :);

areaTable = array2table(pct_matrix1, 'VariableNames', ...
    mineral_labels); %rows according to sectionNames
areaTable1 = addvars(areaTable, sectionNames_sorted, ...
    'Before', 1, 'NewVariableNames', 'Section');

%% Plots

%Attributes
n_minerals = length(mineral_labels);
triplet = zeros(n_minerals, 3);
density = zeros(n_minerals, 1);
for i = 1:n_minerals
   
    temp_label = mineral_labels{i}; %equalized to dbRGB in qupathPhaseMap.m
    index_db = strcmp(dbRGB.Mineral, temp_label);
    index_qp = strcmp(quPathRGB.Mineral, temp_label);
    if sum(index_db) ~= 0
        triplet(i, :) = [dbRGB.R(index_db), dbRGB.G(index_db), dbRGB.B(index_db)];
        density(i) = dbRGB.Density(index_db);
    else %not in db, only quPath colors
        triplet(i, :) = [quPathRGB.R(index_qp), quPathRGB.G(index_qp), quPathRGB.B(index_qp)];
        density(i) = 2.7; %default value (edit manually)
    end
end
triplet1 = triplet/255;

%manual input
index_hole = strcmp(mineral_labels, 'Hole');
triplet1(index_hole, :) = [51, 102, 255]/255;

%converting area% to wt%
pct_matrix2 = pct_matrix1.*density';
totals_col_wt = sum(pct_matrix2, 2);
pct_matrix3 = 100*pct_matrix2./totals_col_wt;

plotStackedV(pct_matrix3, sectionNames_sorted, mineral_labels, triplet1, rootFolder)
% plotStackedV(modal_cell{j}, samples_cell{j}, mineral_labels, triplet1)

