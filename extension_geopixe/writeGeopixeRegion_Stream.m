function writeGeopixeRegion_Stream(change_list, change_items, filename)
% Pass the NUMERIC vector idx_target3 directly, NOT a string

% Read template headers (small) 
currentFuncPath = fileparts(mfilename('fullpath'));
geopixe_file0 = fullfile(currentFuncPath, 'Marco-region0.csv'); %must live next to function

text_2 = fileread(geopixe_file0);
a = regexp(text_2, '#', 'end');
header_comment = text_2(1:a(end));

% Find keys in the template
lines = regexp(text_2(a(end)+1:end), '(?<key>[a-zA-Z_]+),(?<val>[^#\n\r]*)', 'names');
change_map = containers.Map(change_list, change_items);

fid = fopen(filename, 'w');
if fid == -1, error('File error'); end

try
    fprintf(fid, '%s\n', header_comment);
    
    for i = 1:length(lines)
        key = lines(i).key;
        if isKey(change_map, key)
            val = change_map(key);
            
            if strcmp(key, 'Q') && isnumeric(val)                
                % Stream numeric vector directly to file.
                % fprintf is vectorized and highly optimized for this.
                fprintf(fid, 'Q,');
                if ~isempty(val)                    
                    fprintf(fid, '%d,', val(1:end-1)); 
                    fprintf(fid, '%d', val(end)); % Last one no comma
                end
                fprintf(fid, '\n');
            else
                fprintf(fid, '%s,%s\n', key, string(val));
            end
        else
            fprintf(fid, '%s,%s\n', key, strtrim(lines(i).val));
        end
    end
catch ME
    fclose(fid); rethrow(ME);
end
fclose(fid);

end