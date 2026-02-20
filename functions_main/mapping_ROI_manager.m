function [label_map, ROI_data] = mapping_ROI_manager(phasemap_colour, tag_folder)
%The last annotation created (the one with the highest index) wins.

[destinationDir, trial_tag] = fileparts(tag_folder);

% 1. Initialization
[rows, cols, channels] = size(phasemap_colour);
imgSizeGB = (rows * cols * channels * 8) / (1024^3); 

label_map = zeros(rows, cols, 'uint8'); %uint16 
roi_objects = {}; roi_names = {}; 
is_finished = false;
exit_mode = 0; 
% --- ACCESSIBILITY STYLE CONSTANTS ---
MAIN_BG = [0.10 0.10 0.10]; 
SIDEBAR_BG = [0.18 0.18 0.18];
BTN_BG = [0.25 0.25 0.25]; 
TEXT_COLOR = [1 1 1]; % Pure white

LARGE_FONT = 20;      % Titles/Buttons
MEDIUM_FONT = 14;     % List/Popup
SMALL_FONT = 12;      % HUD Details
hFig = figure('Name', 'Region of interest (ROI) annotation tool', 'NumberTitle', 'off', ...
              'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85], ...
              'Color', MAIN_BG, 'MenuBar', 'none', ...
              'CloseRequestFcn', @(s,e) set_exit_flag(2), ...
              'WindowScrollWheelFcn', @scroll_zoom_callback, ...
              'WindowButtonMotionFcn', @ui_motion_logic); 
% Adjusted Axes to give more room for the large HUD
ax = axes('Parent', hFig, 'Position', [0.02 0.15 0.74 0.83], ...
          'Color', 'none', 'XColor', 'none', 'YColor', 'none');
imshow(phasemap_colour, 'Parent', ax);
hold(ax, 'on');
% HUD Text Box (Larger font, high contrast)
hudText = uicontrol('Style', 'edit', 'Units', 'normalized', 'Position', [0.02 0.01 0.60 0.12], ...
          'BackgroundColor', [0, 0, 0], 'ForegroundColor', [0.3 1 0.3], ...
          'FontSize', SMALL_FONT, 'HorizontalAlignment', 'left', 'Max', 2, 'Min', 0, ...
          'Enable', 'inactive', 'String', 'Initializing...');
% UPDATED: White Copy Button with Black Font
uicontrol('Style', 'pushbutton', 'String', '📋 COPY METADATA', 'Units', 'normalized', ...
          'Position', [0.63 0.01 0.13 0.12], 'FontSize', MEDIUM_FONT, 'FontWeight', 'bold', ...
          'BackgroundColor', [1 1 1], 'ForegroundColor', [0 0 0], ...
          'Callback', @copy_metadata_callback);
% Sidebar Background
uicontrol('Style', 'text', 'Units', 'normalized', 'Position', [0.77 0 0.23 1], ...
          'BackgroundColor', SIDEBAR_BG, 'String', '');

rX = 0.79; 
uicontrol('Style', 'text', 'String', 'Annotation Menu', 'Units', 'normalized', ...
          'Position', [rX 0.94 0.18 0.04], 'BackgroundColor', SIDEBAR_BG, ...
          'ForegroundColor', [0.4 0.7 1], 'FontSize', LARGE_FONT, 'FontWeight', 'bold');

% Larger Popup Menu
hType = uicontrol('Style', 'popupmenu', 'Units', 'normalized', 'Position', [rX 0.88 0.18 0.05], ...
          'String', {'freehand', 'polygon', 'rectangle', 'circle'}, ...
          'FontSize', MEDIUM_FONT, 'BackgroundColor', BTN_BG, 'ForegroundColor', TEXT_COLOR);
% Larger Listbox
hList = uicontrol('Style', 'listbox', 'Units', 'normalized', 'Position', [rX 0.28 0.14 0.58], ...
          'FontSize', MEDIUM_FONT, 'BackgroundColor', [0 0 0], 'ForegroundColor', TEXT_COLOR, ...
          'Max', 2, 'Min', 0, 'Callback', @edit_name_callback);
% Sidebar Buttons (Widened for larger icons)
btnX = rX + 0.145;
hBtnAdd = uicontrol('Style', 'pushbutton', 'String', '+', 'Units', 'normalized', 'Position', [btnX 0.80 0.04 0.06], ...
          'FontSize', 24, 'BackgroundColor', [0.1 0.5 0.1], 'ForegroundColor', TEXT_COLOR, ...
          'TooltipString', 'Add Annotation', 'Callback', @add_roi_callback);

hBtnDel = uicontrol('Style', 'pushbutton', 'String', 'X', 'Units', 'normalized', 'Position', [btnX 0.73 0.04 0.06], ...
          'FontSize', 20, 'FontWeight', 'bold', 'BackgroundColor', [0.7 0.1 0.1], 'ForegroundColor', TEXT_COLOR, ...
          'TooltipString', 'Remove Annotation', 'Callback', @delete_roi_callback);
      
hBtnClear = uicontrol('Style', 'pushbutton', 'String', '🗑', 'Units', 'normalized', 'Position', [btnX 0.66 0.04 0.06], ...
          'FontSize', 20, 'BackgroundColor', [0.1 0.4 0.7], 'ForegroundColor', TEXT_COLOR, ...
          'TooltipString', 'Delete All Annotations', 'Callback', @clear_all_callback);
      
hBtnUp = uicontrol('Style', 'pushbutton', 'String', '▲', 'Units', 'normalized', 'Position', [btnX 0.50 0.04 0.06], ...
          'FontSize', 18, 'BackgroundColor', BTN_BG, 'ForegroundColor', TEXT_COLOR, ...
          'TooltipString', 'Move up', 'Callback', @(s,e) move_roi(-1));
      
hBtnDown = uicontrol('Style', 'pushbutton', 'String', '▼', 'Units', 'normalized', 'Position', [btnX 0.43 0.04 0.06], ...
          'FontSize', 18, 'BackgroundColor', BTN_BG, 'ForegroundColor', TEXT_COLOR, ...
          'TooltipString', 'Move down', 'Callback', @(s,e) move_roi(1));
% Save & Exit Button (Much larger)
hBtnSave = uicontrol('Style', 'pushbutton', 'String', '💾 SAVE & EXIT', 'Units', 'normalized', ...
          'Position', [rX 0.15 0.18 0.10], 'FontSize', LARGE_FONT, 'FontWeight', 'bold', ...
          'BackgroundColor', [0.15 0.6 0.15], 'ForegroundColor', TEXT_COLOR, 'Callback', @(s,e) set_exit_flag(1));

% Load Button
hBtnLoad = uicontrol('Style', 'pushbutton', 'String', '📂 LOAD PROGRESS', 'Units', 'normalized', ...
          'Position', [rX 0.04 0.18 0.08], 'FontSize', MEDIUM_FONT, ...
          'BackgroundColor', [0.2 0.3 0.5], 'ForegroundColor', TEXT_COLOR, 'Callback', @load_callback);
allButtons = [hBtnAdd, hBtnDel, hBtnClear, hBtnUp, hBtnDown, hBtnSave, hBtnLoad];
baseColors = {[0.1 0.5 0.1], [0.7 0.1 0.1], [0.1 0.4 0.7], BTN_BG, BTN_BG, [0.15 0.6 0.15], [0.2 0.3 0.5]};
% --- Main Logic ---
while ishandle(hFig)
    if exit_mode == 1
        handle_save_and_exit();
        if is_finished, break; else, exit_mode = 0; end
    elseif exit_mode == 2
        res = questdlg('Exit without saving?', 'Close', 'Yes', 'No', 'No');
        if strcmp(res, 'Yes'), is_finished = true; break; else, exit_mode = 0; end
    end
    pause(0.05);
end
% Post-process logic
ROI_data = struct('ID', {}, 'Position', {}, 'Type', {}, 'Name', {});
if is_finished && ishandle(hFig)
    valid_idx = 1;
    for i = 1:length(roi_objects)
        if isvalid(roi_objects{i})
            mask = createMask(roi_objects{i});
            label_map(mask) = valid_idx; 
            ROI_data(valid_idx).ID = valid_idx;
            ROI_data(valid_idx).Position = roi_objects{i}.Position;
            ROI_data(valid_idx).Type = class(roi_objects{i});
            ROI_data(valid_idx).Name = roi_names{i};
            valid_idx = valid_idx + 1;
        end
    end
end
if ishandle(hFig), delete(hFig); end

%Save ROI label image
imwrite(label_map, fullfile(tag_folder, 'roi_label_map.tif'));

%% --- Internal Callbacks ---
function copy_metadata_callback(~, ~)
    content = get(hudText, 'String');
    if iscell(content), content = strjoin(content, newline); end
    clipboard('copy', content);
    % Visual flash for confirmation
    orig = [1 1 1];
    set(gcbo, 'BackgroundColor', [0.4 1 0.4], 'String', '✅ COPIED!');
    pause(0.8);
    if ishandle(gcbo), set(gcbo, 'BackgroundColor', orig, 'String', '📋 COPY METADATA'); end
end
function ui_motion_logic(~, ~)
    if ~ishandle(hFig), return; end
    cp = get(hFig, 'CurrentPoint');
    for k = 1:length(allButtons)
        bPos = get(allButtons(k), 'Position');
        if cp(1)>=bPos(1) && cp(1)<=bPos(1)+bPos(3) && cp(2)>=bPos(2) && cp(2)<=bPos(2)+bPos(4)
            set(allButtons(k), 'BackgroundColor', baseColors{k} + 0.15);
        else, set(allButtons(k), 'BackgroundColor', baseColors{k}); end
    end
    
    axP = get(ax, 'CurrentPoint');
    x = round(axP(1,1)); y = round(axP(1,2));
    if x>0 && x<=cols && y>0 && y<=rows
        v = squeeze(phasemap_colour(y, x, :));
        % PATH MOVED TO START
        pathStr = sprintf('Path: %s', destinationDir);
        infoStr = sprintf('Size: %.3f GB | Dim: %dx%d | Pos: (%d, %d) | RGB: [%d,%d,%d]', imgSizeGB, cols, rows, x, y, v(1), v(2), v(3));
        set(hudText, 'String', {pathStr; infoStr});
    end
end
function set_exit_flag(mode)
    exit_mode = mode; 
    ghosts = findall(ax, 'Tag', 'ROILastAttempt');
    if ~isempty(ghosts), delete(ghosts); uistack(hFig, 'top'); drawnow; end
end
function add_roi_callback(~, ~)
    axes(ax); types = get(hType, 'String');
    tool_str = strtrim(lower(types{get(hType, 'Value')}));
    drawFunc = str2func(['draw', tool_str]);
    try
        h = drawFunc(ax, 'Color', 'r', 'FaceAlpha', 0.3, 'Tag', 'ROILastAttempt');
        if ~isempty(h) && isvalid(h)
            if isprop(h, 'Position') && ~isempty(h.Position)
                set(h, 'Tag', ''); roi_objects{end+1} = h;
                roi_names{end+1} = sprintf('Annotation %d', length(roi_objects));
                update_listbox(); set(hList, 'Value', length(roi_objects)); 
            else, delete(h); end
        end
    catch, end
end
function delete_roi_callback(~, ~)
    indices = get(hList, 'Value'); if isempty(roi_objects) || isempty(indices), return; end
    for idx = indices, if isvalid(roi_objects{idx}), delete(roi_objects{idx}); end, end
    roi_objects(indices) = []; roi_names(indices) = []; set(hList, 'Value', []); update_listbox();
end
function clear_all_callback(~, ~)
    if isempty(roi_objects), return; end
    res = questdlg('Delete all annotations?', 'Confirm Clear All', 'Yes', 'No', 'No');
    if strcmp(res, 'Yes')
        for k = 1:length(roi_objects), if isvalid(roi_objects{k}), delete(roi_objects{k}); end, end
        roi_objects = {}; roi_names = {}; update_listbox();
    end
end
function move_roi(direction)
    idx = get(hList, 'Value'); if length(idx) ~= 1, return; end 
    new_idx = idx + direction; if new_idx < 1 || new_idx > length(roi_objects), return; end
    roi_objects([idx, new_idx]) = roi_objects([new_idx, idx]);
    roi_names([idx, new_idx]) = roi_names([new_idx, idx]);
    update_listbox(); set(hList, 'Value', new_idx);
end
function handle_save_and_exit()
    [file, path] = uiputfile(fullfile(tag_folder, 'ROI_Progress.mat'), 'Save Progress');
    if isequal(file, 0), return; end 
    temp_save = struct('Position', {}, 'Type', {}, 'Name', {});
    for i = 1:length(roi_objects)
        if isvalid(roi_objects{i})
            temp_save(i).Position = roi_objects{i}.Position;
            temp_save(i).Type = class(roi_objects{i});
            temp_save(i).Name = roi_names{i};
        end
    end
    ROI_data = temp_save; save(fullfile(path, file), 'ROI_data'); is_finished = true;
end
function update_listbox(), set(hList, 'String', roi_names); end
function edit_name_callback(src, ~)
    if strcmp(get(hFig, 'SelectionType'), 'open')
        idx = get(src, 'Value'); if length(idx) ~= 1, return; end 
        newName = inputdlg('Rename Annotation:', 'Edit Name', 1, roi_names(idx));
        if ~isempty(newName), roi_names{idx} = newName{1}; update_listbox(); end
    end
end
function scroll_zoom_callback(~, event)
    C = fcnif(event.VerticalScrollCount > 0, 1.1, 1/1.1);
    cp = ax.CurrentPoint(1, 1:2); xl = ax.XLim; yl = ax.YLim;
    set(ax, 'XLim', cp(1) + (xl - cp(1)) * C, 'YLim', cp(2) + (yl - cp(2)) * C);
end
function load_callback(~, ~)
    [file, path] = uigetfile(fullfile(tag_folder, '*.mat'), 'Load Progress');
    if isequal(file, 0), return; end 
    tmp = load(fullfile(path, file)); if ~isfield(tmp, 'ROI_data'), return; end
    for k = 1:length(roi_objects), if isvalid(roi_objects{k}), delete(roi_objects{k}); end, end
    roi_objects = {}; roi_names = {};
    for k = 1:length(tmp.ROI_data)
        typeParts = strsplit(tmp.ROI_data(k).Type, '.');
        drawFunc = str2func(['draw', lower(typeParts{end})]);
        h = drawFunc(ax, 'Position', tmp.ROI_data(k).Position, 'Color', 'r', 'FaceAlpha', 0.3);
        roi_objects{end+1} = h; roi_names{end+1} = tmp.ROI_data(k).Name;
    end
    update_listbox();
end
function out = fcnif(cond, a, b), if cond, out = a; else, out = b; end; end

end