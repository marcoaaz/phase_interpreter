function [phasemap, section_mask1] = transform_map(phasemap_fg, section_mask, rot_angle, action_code)

if action_code == 1

    phasemap1 = fliplr(phasemap_fg);
    section_mask0 = fliplr(section_mask);

elseif action_code == 0

    phasemap1 = phasemap_fg;
    section_mask0 = section_mask;
end

%counter-clockwise rotation (for matching scans in different microscopes)
phasemap = imrotate(phasemap1, rot_angle); 
section_mask1 = imrotate(section_mask0, rot_angle);

end