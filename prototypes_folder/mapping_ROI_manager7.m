function [label_map, ROI_data] = mapping_ROI_manager7(phasemap_colour, destinationDir)
    % 1. Initialization & Scaling
    screenSize = get(0, 'ScreenSize');
    scaleFactor = max(1, min(screenSize(3)/1920, screenSize(4)/1080));
    [rows, cols, channels] = size(phasemap_colour);
    imgSizeGB = (rows * cols * channels * 8) / (1024^3); 
    
    label_map = zeros(rows, cols, 'uint16'); 
    roi_objects = {}; roi_names = {}; 
    ROI_data = []; 
    is_finished = false;
    exit_mode = 0; 

    % --- STYLE ---
    MAIN_BG = [0.10 0.10 0.10]; SIDEBAR_BG = [0.18 0.18 0.18];
    BTN_BG = [0.25 0.25 0.25]; TEXT_COLOR = [1 1 1];
    L_FONT = 16 * scaleFactor; M_FONT = 14 * scaleFactor; S_FONT = 12 * scaleFactor;      

    hFig = figure('Name', 'ROI ANNOTATOR v27', 'NumberTitle', 'off', ...
                  'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85], ...
                  'Color', MAIN_BG, 'MenuBar', 'none', ...
                  'CloseRequestFcn', @(s,e) set_exit_flag(2), ...
                  'WindowScrollWheelFcn', @scroll_zoom_callback, ...
                  'WindowButtonMotionFcn', @ui_motion_logic); 

    ax = axes('Parent', hFig, 'Position', [0.02 0.16 0.74 0.82], 'Color', 'none', 'XColor', 'none', 'YColor', 'none');
    imshow(phasemap_colour, 'Parent', ax); hold(ax, 'on');

    % HUD (Static Path Line 1)
    hudText = uicontrol('Style', 'edit', 'Units', 'normalized', 'Position', [0.02 0.01 0.60 0.13], ...
              'BackgroundColor', [0, 0, 0], 'ForegroundColor', [0.3 1 0.3], ...
              'FontSize', S_FONT, 'HorizontalAlignment', 'left', 'Max', 2, 'Min', 0, ...
              'Enable', 'inactive', 'String', {['Path: ', destinationDir]; 'Initializing...'});

    uicontrol('Style', 'pushbutton', 'String', '📋 COPY METADATA', 'Units', 'normalized', ...
              'Position', [0.63 0.01 0.13 0.13], 'FontSize', M_FONT, 'FontWeight', 'bold', ...
              'BackgroundColor', [1 1 1], 'ForegroundColor', [0 0 0], 'Callback', @copy_metadata_callback);

    % Sidebar
    uicontrol('Style', 'text', 'Units', 'normalized', 'Position', [0.77 0 0.23 1], 'BackgroundColor', SIDEBAR_BG);
    rX = 0.79; 
    uicontrol('Style', 'text', 'String', 'MENU', 'Units', 'normalized', 'Position', [rX 0.94 0.18 0.04], ...
              'BackgroundColor', SIDEBAR_BG, 'ForegroundColor', [0.4 0.7 1], 'FontSize', L_FONT, 'FontWeight', 'bold');
    
    hType = uicontrol('Style', 'popupmenu', 'Units', 'normalized', 'Position', [rX 0.88 0.18 0.05], ...
              'String', {'freehand', 'polygon', 'rectangle', 'circle'}, 'FontSize', M_FONT);
    hList = uicontrol('Style', 'listbox', 'Units', 'normalized', 'Position', [rX 0.28 0.14 0.58], ...
              'FontSize', M_FONT, 'BackgroundColor', [0 0 0], 'ForegroundColor', TEXT_COLOR, 'Callback', @edit_name_callback);

    btnX = rX + 0.145;
    uicontrol('Style', 'pushbutton', 'String', '+', 'Units', 'normalized', 'Position', [btnX 0.80 0.04 0.06], ...
              'FontSize', 24*scaleFactor, 'BackgroundColor', [0.1 0.5 0.1], 'ForegroundColor', TEXT_COLOR, 'Callback', @add_roi_callback);
    uicontrol('Style', 'pushbutton', 'String', 'X', 'Units', 'normalized', 'Position', [btnX 0.73 0.04 0.06], ...
              'FontSize', 20*scaleFactor, 'BackgroundColor', [0.7 0.1 0.1], 'ForegroundColor', TEXT_COLOR, 'Callback', @delete_roi_callback);
    uicontrol('Style', 'pushbutton', 'String', '▲', 'Units', 'normalized', 'Position', [btnX 0.50 0.04 0.06], ...
              'FontSize', 18*scaleFactor, 'Callback', @(s,e) move_roi(-1));
    uicontrol('Style', 'pushbutton', 'String', '▼', 'Units', 'normalized', 'Position', [btnX 0.43 0.04 0.06], ...
              'FontSize', 18*scaleFactor, 'Callback', @(s,e) move_roi(1));

    uicontrol('Style', 'pushbutton', 'String', '💾 SAVE & EXIT', 'Units', 'normalized', ...
              'Position', [rX 0.15 0.18 0.10], 'FontSize', L_FONT, 'FontWeight', 'bold', ...
              'BackgroundColor', [0.15 0.6 0.15], 'ForegroundColor', TEXT_COLOR, 'Callback', @(s,e) set_exit_flag(1));
    uicontrol('Style', 'pushbutton', 'String', '📂 LOAD PROGRESS', 'Units', 'normalized', ...
              'Position', [rX 0.04 0.18 0.08], 'FontSize', M_FONT, 'Callback', @load_callback);

    % --- Main Loop ---
    while ishandle(hFig)
        if exit_mode == 1, handle_save_and_exit(); if is_finished, break; else, exit_mode = 0; end
        elseif exit_mode == 2, if strcmp(questdlg('Exit?'), 'Yes'), is_finished = true; break; else, exit_mode = 0; end
        end
        pause(0.05);
    end

    % --- CRASH-PROOF POST PROCESS ---
    if is_finished && ishandle(hFig)
        valid_objs = {}; valid_names = {};
        for i = 1:length(roi_objects)
            if isvalid(roi_objects{i})
                valid_objs{end+1} = roi_objects{i};
                valid_names{end+1} = roi_names{i};
            end
        end
        
        % Pre-allocate struct array with total count
        n = length(valid_objs);
        if n > 0
            ROI_data = struct('ID', cell(1,n), 'Position', cell(1,n), 'Type', cell(1,n), 'Name', cell(1,n));
            for i = 1:n
                mask = createMask(valid_objs{i});
                label_map(mask) = i; 
                ROI_data(i).ID = i;
                ROI_data(i).Position = valid_objs{i}.Position;
                ROI_data(i).Type = class(valid_objs{i});
                ROI_data(i).Name = valid_names{i};
            end
        else
            ROI_data = [];
        end
    end
    if ishandle(hFig), delete(hFig); end

    %% --- Internal Callbacks ---
    function handle_save_and_exit()
        [f, p] = uiputfile(fullfile(destinationDir, 'ROI_Progress.mat'), 'Save');
        if isequal(f, 0), return; end 
        % Re-build data purely for save file
        s_data = struct('Position',{}, 'Type',{}, 'Name',{});
        c = 0;
        for i = 1:length(roi_objects)
            if isvalid(roi_objects{i})
                c = c + 1;
                s_data(c).Position = roi_objects{i}.Position;
                s_data(c).Type = class(roi_objects{i});
                s_data(c).Name = roi_names{i};
            end
        end
        ROI_save_data = s_data;
        save(fullfile(p, f), 'ROI_save_data');
        is_finished = true;
    end

    function ui_motion_logic(~, ~)
        if ~ishandle(hFig), return; end
        axP = get(ax, 'CurrentPoint'); x = round(axP(1,1)); y = round(axP(1,2));
        if x>0 && x<=cols && y>0 && y<=rows
            v = squeeze(phasemap_colour(y, x, :));
            set(hudText, 'String', {['Path: ', destinationDir]; ...
                sprintf('Size: %.3f GB | Dim: %dx%d | Pos: (%d, %d) | RGB: [%d,%d,%d]', imgSizeGB, cols, rows, x, y, v(1), v(2), v(3))});
        end
    end

    function copy_metadata_callback(~, ~)
        content = get(hudText, 'String'); if iscell(content), content = strjoin(content, newline); end
        clipboard('copy', content); set(gcbo, 'String', '✅ COPIED!'); pause(0.5); set(gcbo, 'String', '📋 COPY METADATA');
    end

    function add_roi_callback(~, ~)
        axes(ax); types = get(hType, 'String');
        drawFunc = str2func(['draw', strtrim(lower(types{get(hType, 'Value')}))]);
        h = drawFunc(ax, 'Color', 'r', 'FaceAlpha', 0.3);
        if ~isempty(h) && isvalid(h)
            roi_objects{end+1} = h; roi_names{end+1} = sprintf('Annotation %d', length(roi_objects));
            set(hList, 'String', roi_names, 'Value', length(roi_objects));
        end
    end

    function delete_roi_callback(~, ~)
        idx = get(hList, 'Value'); if isempty(idx), return; end
        for i = idx, if isvalid(roi_objects{i}), delete(roi_objects{i}); end, end
        roi_objects(idx) = []; roi_names(idx) = []; set(hList, 'String', roi_names, 'Value', []);
    end

    function move_roi(d)
        idx = get(hList, 'Value'); if length(idx) ~= 1, return; end
        n = idx + d; if n < 1 || n > length(roi_objects), return; end
        roi_objects([idx, n]) = roi_objects([n, idx]); roi_names([idx, n]) = roi_names([n, idx]);
        set(hList, 'String', roi_names, 'Value', n);
    end

    function load_callback(~, ~)
        [f, p] = uigetfile(fullfile(destinationDir, '*.mat')); if isequal(f, 0), return; end
        tmp = load(fullfile(p, f)); data_to_load = tmp.ROI_save_data;
        for k = 1:length(roi_objects), if isvalid(roi_objects{k}), delete(roi_objects{k}); end, end
        roi_objects = {}; roi_names = {};
        for k = 1:length(data_to_load)
            pths = strsplit(data_to_load(k).Type, '.');
            h = str2func(['draw', lower(pths{end})])(ax, 'Position', data_to_load(k).Position, 'Color', 'r', 'FaceAlpha', 0.3);
            roi_objects{end+1} = h; roi_names{end+1} = data_to_load(k).Name;
        end
        set(hList, 'String', roi_names);
    end

    function edit_name_callback(src, ~)
        if strcmp(get(hFig, 'SelectionType'), 'open')
            idx = get(src, 'Value'); if length(idx) ~= 1, return; end 
            newName = inputdlg('Rename:', 'Edit', 1, roi_names(idx));
            if ~isempty(newName), roi_names{idx} = newName{1}; set(hList, 'String', roi_names); end
        end
    end

    function set_exit_flag(m), exit_mode = m; end
    function scroll_zoom_callback(~, e)
        C = fcnif(e.VerticalScrollCount > 0, 1.1, 1/1.1); cp = ax.CurrentPoint(1, 1:2);
        set(ax, 'XLim', cp(1) + (ax.XLim - cp(1)) * C, 'YLim', cp(2) + (ax.YLim - cp(2)) * C);
    end
    function out = fcnif(cond, a, b), if cond, out = a; else, out = b; end; end
end