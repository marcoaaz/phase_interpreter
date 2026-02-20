function writeGeopixeRegion(geopixe_file0, change_list, change_items, filename)
% description: Writing GeoPIXE region

%Input
%change_list : headers that we want to change
%change_items : values of those headers
%filename : looped file name (for each mineral)

%Output
%Individual mask Q-vector (*.csv file)

%The saved Q-vector file can be opened at GeoPIXE software end for spectral
%interrogation (https://asci.synchrotron.org.au/)

%% Preallocate: read GeoPIXE region boiler plate

%geopixel_file0 : GeoPIXE text file (comment section)
%header_str : items available (medata can be re-updated within GeoPIXE)
%data_cell : values of those items
%idx_mtx : char idx ranges of headers and data (table: n_headers x 4)

text_2 = fileread(geopixe_file0);

expression2 = '\n[a-zA-Z_]+[,]';
c = regexp(text_2, expression2, 'start');
d = regexp(text_2, expression2, 'end');

n_characters = length(text_2);
n_items = length(c);

header_str = string(n_items);
data_cell = cell(1, n_items);
idx_mtx = zeros(n_items, 4, 'int64');
for i = 1:n_items

    %headers 
    header_start = c(i) + 1;
    header_end = d(i) - 1;    
    data_start = d(i) + 1;
    try
        data_end = c(i + 1) - 1;
    catch
        data_end = n_characters - 1;
    end

    temp_header = text_2(header_start:header_end);           
    temp_str = strsplit( convertCharsToStrings(text_2(data_start:data_end)) , ',');
    
    header_str(i) = temp_header;
    data_cell{i} = temp_str;
    idx_mtx(i, :) = [header_start, header_end, data_start, data_end];
end
% %debugg
% dim = str2double(data_cell{4});
% n_rows = dim(2); %y
% n_cols = dim(1); %x
% data_cell
% header_str'

%% Customise 

expression1 = '#';
a = regexp(text_2, expression1, "end"); %for rewriting file

n_changes = length(change_list);
n_items = length(header_str);

%update ranges according to new data
idx_mtx_accum = idx_mtx;
data_cell_updated = data_cell;

for ii = 1:n_changes
    change_idx = find(ismember(header_str, change_list{ii}));
    temp_char_idx = idx_mtx_accum(change_idx, :); %row to change
    replacement_char = change_items{ii};
    
    original_length = 1 + temp_char_idx(4) - temp_char_idx(3);
    dif_length = original_length - length(replacement_char);    
    
    idx_mtx_accum(change_idx:end, :) = idx_mtx_accum(change_idx:end, :) - dif_length;
    idx_mtx_accum(change_idx, 3) = temp_char_idx(:, 3); %data start preserved

    data_cell_updated{change_idx} = change_items{ii};
end

%comments
line1 = a(end);
char_1 = [text_2(1:line1), newline];

char_2 = char();
for jj = 1:n_items
    temp_data_str = data_cell_updated{jj};
    temp_data_char = char(strjoin(string(temp_data_str), ','));

    char_2 = [char_2, char(header_str{jj}), ',', temp_data_char, newline];
end

char_full = [char_1, char_2];

fid = fopen(filename, 'w');    % open file for writing (overwrite if necessary)
fprintf(fid,'%s', char_full);          % Write the char array, interpret newline as new line
fclose(fid);                  % Close the file (important)
% open(filename) 

end