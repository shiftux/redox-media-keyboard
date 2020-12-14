include <kle/redox-layout.scad>
include <../keyboard-case.scad>

$fa = 1;
$fs = $preview ? 5 : 2;
bezier_precision = $preview ? 0.05 : 0.025;

// Hacky way to select just the left hand keys from split iris/redox layout
left_keys = [ for (i = redox_layout) if (key_pos(i).x < 8) i ];

/////////////////////////////////////////
// Replicates the original Redox top case
// Sans holes for connectors, see the
// rev0b to see how to do that.
/////////////////////////////////////////
r0_x0 = 88.2;
r0_y0 = -100.8;
r0_x1 = 7.9;
r0_y1 = -1.45;
r0_x2 = 134.7;
r0_x3 = 169.2;
r0_y3 = -75.5;
r0_x6 = 154.32;
r0_y6 = -101.26;
r0_x4 = 145.0;
r0_y4 = -117.6;
r0_x5 = 118.65;
rev0_reference_points = [
    [r0_x0, r0_y0],
    [r0_x1, r0_y0],
    [r0_x1, r0_y1],
    [r0_x2, r0_y1],
    [r0_x3, r0_y3],
    [r0_x6, r0_y6],
    [r0_x4, r0_y4],
    [r0_x5, r0_y4],
    ];
rev0_screw_holes = [ for (p = rev0_reference_points) if (p.x != r0_x4) p];
rev0_tent_positions = [
    // [X, Y, Angle]
    [[3.3, -89.0], 180],
    [[3.3, -13], 180],
    [[145.1, -13], 25],
    [[155.7, -108], -30],
    ];
module rev0_outer_profile() {
    fillet(r = 5, $fn = 20)
        offset(r = 5, chamfer = false)
        polygon(points = rev0_reference_points, convexity = 3);
}
module rev0_top_case() {
    top_case(left_keys, rev0_screw_holes, raised = false) rev0_outer_profile();
}
module rev0_bottom_case() {
    bottom_case(rev0_screw_holes, rev0_tent_positions) rev0_outer_profile();
}

/////////////////////////////////////////////////
// Revised case with bezier based curved outlines
/////////////////////////////////////////////////
r0b_x0 = 88.2;
r0b_y0 = -100.8;
r0b_x1 = 0.9;
r0b_y1 = -3.45;
r0b_y1b = -13.45;
r0b_x2 = 146.7;
r0b_x3 = 169.2;
r0b_y3 = -75.5;
r0b_x6 = 154.32;
r0b_y6 = -101.26;
r0b_x4 = 145.0;
r0b_y4 = -117.6;
r0b_x5 = 118.65;

// additional points to enlarge top part, allowing for media buttons and control
r0b_x7 = 0.9;
r0b_y7 = 16;
r0b_x8 = 80;
r0b_y8 = 24;
r0b_x9 = 146.7;
r0b_y9 = 3;
r0b_x10 = 36;
r0b_y10 = 28;

rev0b_reference_points = [
    [r0b_x0-1, r0b_y0-3],     // Bottom mid
    [r0b_x1, r0b_y0-5],       // Bottom left
    [r0b_x1, r0b_y1],         // Top left
    [r0b_x2, r0b_y1b],        // Top right
    [r0b_x3+2, r0b_y3-6.5],    // Right
    [r0b_x6+5, r0b_y6],        // Screw
    [r0b_x4+5, r0b_y4],        // Bottom
    [r0b_x5+5, r0b_y4],        // Screw
    ];
//rev0b_screw_holes = [ for (p = rev0b_reference_points) if (p.x != r0b_x4+5) p];
rev0b_screw_holes = [
    //[r0b_x1+5, r0b_y0],           // Bottom left
    [r0b_x1+27.5, r0b_y0+17.5],           // Bottom left, under caps

    //[r0b_x1+5, r0b_y1-5],       // Top left
    [r0b_x1+27.5, r0b_y1-4],       // Top left
    //[r0b_x1+44.5, r0b_y1-1],      // Top leftish
    [86.5,-2],                    // Top middle
    //[r0b_x2-13.5, r0b_y1b+3],     // Top right
    [r0b_x2-6.5,  r0b_y3+40],   // Top right, under caps

    //[r0b_x2+4.5,  r0b_y3+7],     // Right
    [r0b_x6-1.5, r0b_y6+0.9],      // Right, under caps

    //[r0b_x5-35, r0b_y4+20],      // Bottom
    ];
rev0b_tent_positions = [
    // [X, Y, Angle]
    [[0.8, -18], 180],
    [[0.8, -91.0], 180],
    [[146.8, -25], 5],
    [[151.2, -117.3], -30],
    ];

      /* CONTROL              POINT                       CONTROL      */
bzVec = [                     [r0b_x7,r0b_y7],            OFFSET([10, 0]), // Top left
         OFFSET([-20, -1]),   [r0b_x10,r0b_y10],          OFFSET([5, 0]), // Top
         OFFSET([-1, 0]),    [r0b_x8,r0b_y8],            OFFSET([25, 0]), // Top
         POLAR(25, 140),      [r0b_x9,r0b_y9],            SHARP(), // Top right
         POLAR(32, 153),      [r0b_x3+2,r0b_y3-6.5],      SHARP(), // Right
         // Skip screw
         SHARP(),             [r0b_x4-1.5, r0b_y4-12.5],  POLAR(82, 149), // Bottom right
         POLAR(18, 0),        [r0b_x0-41, r0b_y0-5],      POLAR(5, 180), // Bottom mid
         SHARP(),             [r0b_x1, r0b_y0-5],         SHARP(),
         SHARP(),             [r0b_x1, r0b_y1],
    ];
// eplanation of Bezier curve module: https://www.thingiverse.com/thing:2207518
b1 = Bezier(bzVec, precision = bezier_precision);
module rev0b_outer_profile() {
    offset(r = 5, chamfer = false, $fn = 20) // Purposely slightly larger than the negative offset below
    offset(r = -4.5, chamfer = false, $fn = 20)
        polygon(b1);
}

// media buttons
top_surface_offset = 4;
media_top_diameter = 17;
media_bottom_diameter = 12.7;
bottom_height = 15;
media_top_height = 8;
hex_corner_diameter = 16.7;
remaining_wall_thickness = 2;
module media_button(x,y,z) {
    color("silver") translate([x, y, z+top_surface_offset])
        union() {
            cylinder(d = media_top_diameter, h = media_top_height);
            translate([0, 0, -media_top_height]) cylinder(d = media_bottom_diameter, h = -bottom_height);
        }
}
module media_button_hole(x,y,z) {
    translate([x, y, z+top_surface_offset]) rotate([0, 180, 0]) union () {
        cylinder(d = media_bottom_diameter, h = remaining_wall_thickness, $fn=40);
        translate([0, 0, remaining_wall_thickness]) cylinder(d = hex_corner_diameter, h = bottom_height, $fn=6);
    }
}

// volume knob / scroll wheel
// ideal with https://www.velleman.eu/products/view/?id=439226
vol_top_diameter = 29;
vol_top_height = 17;
vol_hole_diam = 7.5;
vol_hole_depth = 10;
encoder_pcb_width = 24;
encoder_pcb_length = 47;
encoder_pcb_hole = 12;
encoder_pcb_shift = 10;
module volume_knob(x,y,z){
    color("silver") translate([x, y, z+top_surface_offset]) cylinder(d = vol_top_diameter, h = vol_top_height);
}
module volume_knob_hole(x,y,z){
    translate([x, y, z+top_surface_offset]) rotate([0, 180, 0]) union() {
        cylinder(d = vol_hole_diam, h = vol_hole_depth, $fn=40);
        translate([-encoder_pcb_shift, -2, z-remaining_wall_thickness/2]) cube([encoder_pcb_length, encoder_pcb_width, encoder_pcb_hole], center = true);
    }
}

threaded_diameter = 6.7;
threaded_height = 5;
body_diameter = 8;
module trs_jack(x,y,z,theta_z){
    translate([x, y, z]) rotate([0, 90, theta_z]) union() {
        cylinder(d = body_diameter, h = body_diameter, $fn=30);
        translate([0,0,body_diameter]) cylinder(d = threaded_diameter, h = threaded_height, $fn=30);
    }
}

// micro-usb holder
// ideal for https://www.brack.ch/delock-usb-otg-kabel-microb-shapecable-0-15-m-526554?query=micro+usb+buchse&active_search=true
holder_width = 12.2;
holder_height = 8.8;
holder_side_radius = 9;
holder_side_x_shift = 9.5;
module usb_holder_hole(x,y,z){
    translate([x, y, z]) rotate([0, 0, 0]) cube([holder_width,5+1,holder_height]);
    // color("black") translate([x, y, z+holder_height]) rotate([180, 0, 0]) cube([holder_width,11,holder_height]);
}
module usb_holder_sides(x,y,z){
    translate([x-holder_side_x_shift, y, z-4.2]) rotate([0, 0, 0])
    difference() {
        union() {
            translate([x-0.2, y-26.5, z]) {cylinder(d = 2*holder_side_radius, h = holder_height, $fn=40);}
            translate([x-holder_width-2*holder_side_radius+1.6, y-26.5, z]) {cylinder(d = 2*holder_side_radius, h = holder_height, $fn=40);}
            translate([x-holder_width+4, y-34, z]) {cube([3.5,5,holder_height]);}
            translate([x-holder_width-11.9, y-34, z]) {cube([3.5,5,holder_height]);}
            translate([x-holder_width-11.9, y-34, z-4]) {cube([20,12,4.5]);}
        }
        translate([x-holder_width+7.2, y-38, z-4]) cube([20,25,holder_height+4.5]);
        translate([x-holder_width, y-22, z-4]) cube([20,25,holder_height+4.5]);
        translate([x-holder_width-31.5, y-38, z-4]) cube([20,25,holder_height+4.5]);
        translate([x-holder_width-28, y-22, z-4]) cube([20,25,holder_height+4.5]);
    }
}


media_button_1_x = 115;
media_button_1_y = 7;
media_button_2_x = 90;
media_button_2_y = 11;
vol_knob_x = r0b_x10;
vol_knob_y = 13;
module rev0b_top_media(raised = true) {
    difference() {
        union(){ top_case(left_keys, rev0b_screw_holes, chamfer_height = raised ? 5 : 2.5, chamfer_width = 2.5, raised = raised) rev0b_outer_profile();
            // media_button(media_button_1_x,media_button_1_y,top_case_raised_height);
            // media_button(media_button_2_x,media_button_2_y,top_case_raised_height);
            // volume_knob(vol_knob_x,vol_knob_y,top_case_raised_height);
        }
        volume_knob_hole(vol_knob_x,vol_knob_y,top_case_raised_height);
        media_button_hole(media_button_1_x,media_button_1_y,top_case_raised_height);
        // media_button_hole(media_button_2_x,media_button_2_y,top_case_raised_height);
    }
}

trs_x = 122;
trs_y = 6.9;
trs_z = wall_thickness + 6;
trs_theta_z = 66;
usb_holder_x = 30;
usb_holder_y = 23;
usb_holder_z = wall_thickness+2.201;
module rev0b_bottom_media() {
    usb_holder_sides(usb_holder_x,usb_holder_y,usb_holder_z);
    difference() {
        bottom_case(rev0b_screw_holes, rev0b_tent_positions) rev0b_outer_profile();
        usb_holder_hole(usb_holder_x,usb_holder_y,usb_holder_z);
        trs_jack(trs_x,trs_y,trs_z,trs_theta_z);
        //%trs_jack(trs_x,trs_y,trs_z,trs_theta_z);
        translate([0, 0, wall_thickness + 0.01]) {
            // Case holes for connectors etc. The second version of each is just
            // For preview view
            // translate([34, -8.45, 0.05]) rotate([0, 0, 8.8]) {
            //     reset_microswitch();
            //     %reset_microswitch(hole = false);
            // }
            // translate([13, -5.5, 0]) rotate([0, 0, 4]) {
            //     micro_usb_hole();
            //     %micro_usb_hole(hole = false);
            // }
            // translate([130.5, -7.5, 0]) rotate([0, 0, -24]) {
            //     mini_usb_hole();
            //     %mini_usb_hole(hole = false);
            // }
        }
    }
}

part = "top-media";
explode = 0;
if (part == "outer") {
    //BezierVisualize(bzVec);
    offset(r = -2.5) // Where top of camber would come to
        rev0b_outer_profile();
    for (pos = rev0b_screw_holes) {
        translate(pos) {
            polyhole2d(r = 3.2 / 2);
        }
    }
    #key_holes(left_keys);

} else if (part == "top-media") {
        rev0b_top_media(true);

} else if (part == "bottom-media") {
    rev0b_bottom_media();

} else if (part == "assembly") {
    %translate([0, 0, plate_thickness + 30 * explode]) key_holes(left_keys, "keycap");
    %translate([0, 0, plate_thickness + 20 * explode]) key_holes(left_keys, "switch");
    rev0b_top_media();
    translate([0, 0, -bottom_case_height -20 * explode]) rev0b_bottom_media();

} else if (part == "holetest") {
    * translate([-66.5, 20.25]) top_case([left_holes[0], left_holes[1], left_holes[7], left_holes[8]], [], raised = true)
        translate([66.5, -20.25]) square([46, 49], center = true);
    translate([-66.5, 20.25]) difference() {
        chamfer_extrude(height = plate_thickness + top_case_raised_height, chamfer = 5, width = 2.5, faces = [false, true]) translate([66.5, -20.25]) square([46, 49], center = true);
        translate([0, 0, 4])
        key_holes([left_holes[0], left_holes[1], left_holes[7], left_holes[8]]);
    }
}


// Requires my utility functions in your OpenSCAD lib or as local submodule
// https://github.com/Lenbok/scad-lenbok-utils.git
use<../Lenbok_Utils/utils.scad>
// Requires bezier library from https://www.thingiverse.com/thing:2207518
use<../Lenbok_Utils/bezier.scad>
