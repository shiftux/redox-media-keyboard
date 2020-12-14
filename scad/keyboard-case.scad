unit = 19.05;            // Unit size of spacing between keys

cherry_plate_width = 14; // Width of hole in plate for key insertion. Adjust if needed

plate_thickness = 4;   // Fairly thick for strength, ideally print this section with high infill
top_case_raised_height = 7.2 + 1; // Distance between plate and bottom of keycap plus a little extra, for raised top case
bottom_case_height = 13;  // Enough room to house electonics
wall_thickness = 2;     // Sides and bottom of case
depth_offset = 0;       // How much of side wall to include below top plate

// Case screw sizes
standoff_rad = 7 / 2;
screw_rad = 3.2 / 2;
screw_head_rad = 6 / 2;
screw_length = 8;
bottom_screws = false; // Default is to screw down from the top

themes = [
    //    case,    keycap, keyswitch,  keystem
    ["#101010", "#130044", "#222222", "#aa3333"],
    ["#180054", "#73d373", "#222222", "#aa3333"],
    ["#bbbbff", "#73d373", "#222222", "#aa3333"],
    ["#9999bb", "#252525", "#cccccc", "#553333"],
    ];
theme = 3;
case_color = themes[theme].x;
keycap_color = themes[theme].y;
keyswitch_color = themes[theme].z;
keystem_color = themes[theme][3];

// Create a hole where a switch can be inserted. The top of the hole is at 0
cherry_clip_recess_z = 1.3; // How far below the top the recess begins
cherry_clip_recess_width = 6; // How much of the side is taken up by the recess
cherry_clip_recess_depth = 1.0; // How far in does the clip go
cherry_clip_recess_height = 4.0; // How far down clip recess go
module switch_hole(size, depth = 5) {
    translate([0, 0, -depth]) {
        linear_extrude(height = depth + 0.01, center = false, convexity = 3)
            square([cherry_plate_width, cherry_plate_width], center = true);
        translate([0, 0, depth - cherry_clip_recess_z - cherry_clip_recess_height]) linear_extrude(height = cherry_clip_recess_height, center = false, convexity = 3)
            for (r = [0, 90])
                rotate([0, 0, r])
                    square([cherry_plate_width + 2 * cherry_clip_recess_depth, cherry_clip_recess_width], center = true);
    }
}

// A keyswitch for preview purposes
cherry_switch_width = 14;
cherry_switch_depth = 5.2;
module cherry_keyswitch() {
    color(keystem_color) translate([0, 0, 5]) {
        translate([0, 0, 0.5]) cube([7, 5.7, 1], center = true);
        translate([0, 0, 1 + 1.8])
            for (r = [0, 90])
                rotate([0, 0, r])
                cube([4.0, 1.2, 3.6], center = true);
    }
    color(keyswitch_color) {
        hull() {
            translate([0, 0, 0.99]) linear_extrude(height = 0.01, center = false, convexity = 3)
                square([14, 14], center = true);
            translate([0, 0, 5.6]) linear_extrude(height = 0.01, center = false, convexity = 3)
                square([11, 11], center = true);
        }
        translate([0, 0, 0.5]) cube([15.6, 15.6, 1], center = true);
        translate([0, 0, -8.3]) cylinder(r = 3.8 / 2, h = 5, $fn = 8);
        hull() {
            linear_extrude(height = 0.01, center = false, convexity = 3)
                square([cherry_switch_width, cherry_switch_width], center = true);
            translate([0, 0, -cherry_switch_depth]) linear_extrude(height = 0.01, center = false, convexity = 3)
                square([cherry_switch_width-0.5, cherry_switch_width-0.5], center = true);
        }
    }
}

// Something roughly DSA-ish for preview purposes
keycap_depth_offset = 7.2;  // Distance from bottom of keycap to top of plate.
module simple_keycap(size) {
    color(keycap_color) translate([0, 0, keycap_depth_offset]) hull() {
        linear_extrude(height = 0.01, center = false, convexity = 3)
            offset(delta = -0.4, chamfer = false) square(size * unit, center = true);
        translate([0, 0, 8]) linear_extrude(height = 0.01, center = false, convexity = 3)
            offset(r = 2, $fn = 16) offset(delta = -5.5) square(size * unit, center = true);
    }
}

// Negative space for a keycap for raised top cases
module keycap_hole(size, depth = top_case_raised_height) {
    linear_extrude(height = depth + 1, center = false, convexity = 3)
        offset(delta = 0.4) square(size * unit, center = true);
}

// Negative space for a key switch plus keycap
module case_switch_hole(size) {
    keycap_hole(size);
    switch_hole(size);
}

// For subtracting a hole in the bottom case for a microswitch
module reset_microswitch(hole = true) {
    color("#202020") cube([14, 6, 6], center = false);
    color("red") translate([4, 0.01, 1])  cube([2, hole ? 10 : 7, 4], center = false);
}

// Typical mini USB breakout boards from e.g. Aliexpress
mini_usb_screw_dia = 3.0;
mini_usb_screw_rad = (mini_usb_screw_dia - 0.6) / 2; // Smaller than M3 to tap into
mini_usb_screw_sep = 20;
mini_usb_hole_height = 7.5;
module mini_usb_hole(hole = true) {
    color("green") translate([0, -11, pcb_thickness/2]) cube([25.5, 19.5, pcb_thickness], center = true);
    if (hole) {
        translate([0, 0, mini_usb_hole_height/2])  rotate([90, 0, 0]) roundedcube([10, mini_usb_hole_height, 10], r=1.5, center=true, $fs=1);
    }
    color("silver") translate([0, -5, mini_usb_hole_height/2])  rotate([90, 0, 0]) cube([7.6, 3.7, 9.2], center=true, $fs=1);
    for (i = [-1,1], j = [0, 14]) {
        translate([i*mini_usb_screw_sep/2, -4-j, -5]) polyhole(r=mini_usb_screw_rad, h=10);
    }
}

// Typical micro USB breakout boards from e.g. Aliexpress
micro_usb_screw_dia = 3.0;
micro_usb_screw_rad = (micro_usb_screw_dia - 0.6) / 2; // Smaller than M3 to tap into
micro_usb_screw_sep = 9;
micro_usb_hole_width = 11;
micro_usb_hole_height = 7.5;
micro_usb_socket_height = 2.5;
pcb_thickness = 2;
module micro_usb_hole(hole = true) {
    color("green") translate([0, -8, pcb_thickness/2]) cube([14, 14, pcb_thickness], center = true);
    color("silver") {
        if (hole) {
            translate([0, 1, pcb_thickness+micro_usb_socket_height/2]) rotate([90, 0, 0]) roundedcube([micro_usb_hole_width, micro_usb_hole_height, 10], r=1.5, center=true, $fs=1);
        }
        translate([0, -3, pcb_thickness + micro_usb_socket_height / 2]) rotate([90, 0, 0]) cube([7.5, micro_usb_socket_height, 7], center = true, $fs = 1);
    }
    for (i = [-1,1]) {
        translate([i * micro_usb_screw_sep/2, -8, -5]) polyhole(r = micro_usb_screw_rad, h = 15);
    }
}

// You can use this for things that don't need to vary each child according to the key (e.g. size)
module key_positions(keys) {
    // Mirror because KLE has Y axis reversed
    mirror([0, 1, 0]) for (key = keys)
        position_key(key, unit = unit)
            children();
}

module key_holes(keys, type = "both") {
    //echo("Number of keys:",len(keys));
    // Mirror because KLE has Y axis reversed
    mirror([0, 1, 0]) for (key = keys) {
        position_key(key, unit = unit)
            if (type == "both") {
                case_switch_hole(key_size(key));
            } else if (type == "plate") {
                switch_hole(key_size(key));
            } else if (type == "switch") {
                cherry_keyswitch();
            } else if (type == "keycap") {
                simple_keycap(key_size(key));
            }
    }
}

module screw_positions(screws) {
    for (screw = screws) translate(screw) children();
}

module screw_holes(screws, screw_depth = 8, screw_head_depth = plate_thickness + top_case_raised_height) {
    screw_positions(screws) {
        mirror([0, 0, 1]) translate([0, 0, -screw_head_depth]) bolthole(r1=screw_head_rad, r2=screw_rad, h1=screw_head_depth, h2=screw_depth);
    }
}


// M5 bolt tenting
tent_bolt_rad = 5 / 2;
tent_nut_rad = 9.4 / 2;
tent_nut_height = 3.5;
tent_attachment_width = 35;
module tent_support(position, angle, height = bottom_case_height, lift = 0) {
    base_chamfer = 2.5;
    off = apothem(tent_nut_rad, 6) + 0.5;
    translate([position.x, position.y, lift]) rotate([0, 0, angle]) {
        difference() {
            chamfer_extrude(height = height, chamfer = base_chamfer, faces = [true, false]) {
                hull() {
                    translate([-6.5, 0]) square([0.1, tent_attachment_width], center = true);
                    translate([off, 0]) circle(r = tent_bolt_rad + base_chamfer + 1.5);
                }
            }
            //translate([-10,-20, -0.1]) cube([10-base_chamfer, 40, bottom_case_height+1], center=false);
            // Screw hole
            translate([off, 0, -0.1]) polyhole(r=tent_bolt_rad, h=height+1);
            // Nut hole
            translate([off, 0, height-tent_nut_height]) rotate([0, 0, 60/2]) cylinder(r=tent_nut_rad, h=tent_nut_height+0.1, $fn=6);
        }
    }
}


// children should be a 2d polygon specifying the outer border of case
module top_plate(keys, screws) {
    screw_offset = -1.0;
    total_depth = plate_thickness;
    color(case_color) difference() {
        render() linear_extrude(height = total_depth, $fn = 25) children();
        translate([0, 0, plate_thickness + screw_offset]) screw_holes(screws);
        translate([0, 0, plate_thickness]) key_holes(keys);
    }
}

// children should be a 2d polygon specifying the outer border of case
module top_case(keys, screws, raised = false, chamfer_height = 2.5, chamfer_width, chamfer_faces = true, tent_positions = [], standoffs = false) {
    screw_offset = 0;
    chamfer_w = chamfer_width == undef ? chamfer_height : chamfer_width;
    chamfer_f = chamfer_faces ? [false, true] : [false, false];
    total_depth = plate_thickness + (raised ? top_case_raised_height : 0);
    color(case_color) difference() {
        union() {
            render() translate([0, 0, -depth_offset]) chamfer_extrude(height = total_depth + depth_offset, chamfer = chamfer_height,
                                                                        width = chamfer_w, faces = chamfer_f, $fn = 25) children();
            translate([0, 0, -depth_offset]) for(tent = tent_positions) {
                height = len(tent) > 2 ? tent[2] : plate_thickness + depth_offset;
                tent_support(tent[0], tent[1], height = height, lift = depth_offset + plate_thickness - height);
            }
        }

        difference() {
            render() translate([0, 0, -depth_offset - 0.1])
                chamfer_extrude(height = depth_offset + 0.1, chamfer = chamfer_height * 0.7, width = chamfer_w * 0.7, faces = [false, false], $fn = 25)
                offset(delta = -wall_thickness) children();
            if (standoffs) {
                screw_positions(screws)
                    hull() {
                    translate([0, 0, - depth_offset - 0.2]) polyhole(r = standoff_rad, h = 0.1);
                    polyhole(r = standoff_rad, h = 0.1);
                }
            }
        }
        translate([0, 0, plate_thickness + screw_offset]) screw_holes(screws);
        translate([0, 0, plate_thickness]) key_holes(keys);
    }
}


// children should be a 2d polygon specifying the outer border of case
module bottom_case(screws, tent_positions = [], raised = false, chamfer_height = 2.5, chamfer_width, chamfer_faces = [true, false], standoffs = true) {
    chamfer_w = chamfer_width == undef ? chamfer_height : chamfer_width;
    wall_height = bottom_case_height + (raised ? plate_thickness + top_case_raised_height : -depth_offset);
    color(case_color) difference() {
        union() {
            render() chamfer_extrude(height = wall_height, chamfer = chamfer_height, width = chamfer_w, faces = chamfer_faces, $fn = 25)
                children();
            for(tent = tent_positions) {
                height = len(tent) > 2 ? tent[2] : bottom_case_height;
                lift = len(tent) > 3 ? tent[3] : 0;
                tent_support(tent[0], tent[1], height = height, lift = lift);
            }
        }

        difference() {
            render() translate([0, 0, wall_thickness])
                chamfer_extrude(height = wall_height, chamfer = chamfer_height * 0.7, width = chamfer_w * 0.7, faces = [true, false], $fn = 25)
                offset(delta = -wall_thickness) children();
            if (standoffs) {
                standoff_height = bottom_case_height - depth_offset;
                screw_positions(screws)
                    hull() {
                    translate([0, 0, standoff_height]) polyhole(r = standoff_rad, h = 0.1);
                    polyhole(r = standoff_rad + 1, h = 0.1);
                }
            }
        }

        if (bottom_screws) {
            screw_positions(screws) {
                translate([0, 0, -0.1]) bolthole(r1=screw_head_rad, r2=screw_rad, h1=screw_head_depth, h2=screw_length, membrane = screw_head_depth > 0 ? 0.2 : 0);
            }
        } else {
            screw_rad = screw_rad - 0.4; // Tightened screw holes for tapping into
            translate([0, 0, wall_thickness]) screw_positions(screws) polyhole(r = screw_rad, h = 50);
        }
    }
}

// Requires my utility functions in your OpenSCAD lib or as local submodule
// https://github.com/Lenbok/scad-lenbok-utils.git
use<Lenbok_Utils/utils.scad>

