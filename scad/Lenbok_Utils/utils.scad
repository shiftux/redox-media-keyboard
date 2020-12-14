// My utility functions

// Put it in your openscad library path and use with:
// use<Lenbok_Utils/utils.scad>

// Example improved resolution control
//$fa=1;
//$fs=5; // Use for fast rendering
//$fs=1; // Uncomment for export

fudge = 0.02;

// Some default screw characteristics - for M3 screws
defScrewRad = 3.5/2;
defScrewDepth = 5;
defScrewHeadRad = 6/2;
defScrewHeadDepth = 3.5;

defLayer = 0.25; // default layer thickness
tolerance = 0.5;

/** Calculates length of hypotenuse according to pythagoras theorum */
function pythag(x, y) = sqrt(x * x + y * y);

/** Converts a vector to unit length */
function unit_vector(v) = v / norm(v);

/** Length of apothem given radius and number of sides */
function apothem(r, n = 6) = r * cos(180/n);

/** Length of radius given apothem and number of sides */
function inv_apothem(a, n = 6) = a / cos(180/n);

/** From the OpenSCAD wiki. */
function sublist(list, from=0, to) =
    from > to
    ? []
    : let(end = to==undef ? len(list) - 1 : to)
        [for(i = [from : end]) list[i]];

/** From the OpenSCAD wiki. */
module fillet(r = 1) {
    offset(r = -r) offset(delta = r) children();
}

/** From the OpenSCAD wiki. */
module round(r = 1) {
    offset(r = r) offset(delta = -r) children();
}

// Copyright 2011 Nophead (of RepRap fame)
// Using this holes should come out approximately right when printed
module polyhole2d(r) {
    n = max(round(4 * r), 3);
    rotate([0, 0, 180]) circle(r = r / cos (180 / n), $fn = n);
}
module polyhole(r, h, center = false) {
    translate(center ? [0, 0, -h / 2] : [0, 0, 0]) linear_extrude(height = h) polyhole2d(r);
}

module test_polyhole(){
    difference() {
	cube(size = [100, 27, 3]);
        union() {
    	    for(i = [1:10]) {
                translate([(i * i + i) / 2 + 3 * i, 8, -1])
                polyhole(h = 5, r = i / 2);
                
                assign(d = i + 0.5)
                translate([(d * d + d) / 2 + 3 * d, 19, -1])
                polyhole(h = 5, r = d / 2);
    	    }
        }
    }
}

/**
 * Reorients children with respect to the given vector
 * @param v the vector
 * @param a the assumed current origin vector (default Z axis)
 */
module orient(v, a = [0, 0, 1], roll = 0) {
    angle = acos((a * v) / (norm(a) *norm(v)));
    rotate(a = angle, v = cross(a, v))
        rotate([0, 0, roll])
        children();
}

/**
 * Projection from 3d children to 2d along a plane defined by a vector
 * @param v the vector
 */
module projection_plane(v, roll = 0) {
    projection(cut = true) orient(v, roll = roll) translate(-v) children();
}

/**
 * Perform a difference between the children and the plane
 * defined by the supplied vector.
 * @param v the vector
 * @param near if true, keep the side closest to the origin, if false, keep the side away from the origin
 */
module difference_plane(v, near = true) {
    huge = 10000; // Too large gives preview artifacts
    offset = near ? huge / 2 : -huge / 2;
    translate(v) orient(v, roll = 180) difference() {
        orient(v, roll = 180) translate(-v) children();
        translate([0, 0, offset]) cube([huge, huge, huge], center = true);
    }
}

/**
 * Produce a slice defined by the projection along a plane, expanded to the specified width.
 * @param v the vector defining the plane
 * @param thickness the thickness of the slice to create
 */
module slice(v, thickness = 2) {
    translate(v) orient(v, roll = 180) difference() {
        translate([0, 0, -thickness / 2]) linear_extrude(height = thickness) projection_plane(v, roll = 180) children();
    }
}

/**
 * Remove a slice of an object along a plane.
 * @param v the vector defining the plane
 * @param thickness the thickness of the slice to remove
 * @param rejoin if true, re-join the parts
 */
module remove_slice(v, thickness = 2, rejoin = false) {
    fudge = 0.01; // allow some overlap to avoid coincident faces
    shift = rejoin ? unit_vector(v) * (thickness / 2 + fudge) : 0;
    v1 = v - unit_vector(v) * thickness / 2;
    v2 = v + unit_vector(v) * thickness / 2;
    s2 = v * v2 >= 0 ? 1 : -1;
    translate(shift) difference_plane(v1, near = v * v1 >= 0) children();
    translate(-shift) difference_plane(v2 * s2, near = v * v2 <= 0) children();
}

/**
 * insert a slice of an object along a plane and re-join the parts.
 * @param v the vector defining the plane
 * @param thickness the thickness of the slice to remove
 */
module insert_slice(v, thickness = 2) {
    fudge = 0.01; // allow some overlap to avoid coincident faces
    shift = unit_vector(v) * (thickness / 2 - fudge);
    translate(-shift) difference_plane(v, near = true) children();
    slice(v, thickness = thickness) children();
    translate(shift) difference_plane(v, near = false) children();
}

/**
 * Example: centerxy(cubesize) cube(cubesize, center = false);
 */
module centerxy(size = [0, 0]) {
    translate([-size[0] / 2, -size[1] / 2, 0]) children();
}

/**
 * Make an oval
 * @param rWidth the radius of the width
 * @param rHeight the radius of the height
 */
module oval(rWidth = 20, rHeight = 10) {
    scale([1, rHeight / rWidth, 1]) circle(r = rWidth);
}


/** 
 * Displays the current build volume of my original mendel
 */
module mendelBuildVolume() {
    %translate([-90, -80, 0]) cube([90+101,160,55]);
    %translate([-73, -80, 0]) cube([73+93,160,125]);
}

/**
 * Take the convex hull of successive pairs of children
 * @children shapes to successively connect
 */
module hullchain() {
    for (i = [0:$children - 2]) {
        hull() {
            children(i);
            children(i + 1);
        }
    }
}

/**
 * Make an object suitable for creating a hole for a countersink screw.
 * @param r1 head (widest) radius
 * @param r2 screw (narrowest) radius
 * @param h1 depth of head to start of countersink
 * @param h2 depth of screw from start of countersink to end (i.e. total length = h1+h2)
 */
module countersink(r1=defScrewHeadRad, r2=defScrewRad, h1=defScrewHeadDepth, h2=defScrewDepth) {
    sinkheight=r1-r2;
    polyhole(r = r1, h = h1 + fudge);
    translate([0, 0, h1]) cylinder(r1 = r1, r2 = r2, h = sinkheight + fudge);
    translate([0, 0, h1 + sinkheight]) polyhole(r = r2, h = h2 - sinkheight);
}

/**
 * Make an object suitable for creating a hole for a regular screw.
 * @param r1 head (widest) radius
 * @param r2 screw (narrowest) radius
 * @param h1 depth of screw 
 * @param h2 depth of screw head (i.e. total length = h1+h2)
 * @param membrane set this to layer thickness to leave a one-layer membrane to be removed after printing
 */
module bolthole(r1=defScrewHeadRad, r2=defScrewRad, h1=defScrewHeadDepth, h2=defScrewDepth, membrane=-fudge) {
    polyhole(r = r1, h = h1 - membrane / 2);
    translate([0, 0, h1 + membrane / 2]) polyhole(r = r2, h = h2 - membrane / 2);
}

module standoffpos(r1 = defScrewHeadRad, r2 = defScrewRad, r3 = 1.5, h1 = defScrewHeadDepth, h2 = defScrewDepth) {
    cylinder(r = r1 + r3, h = h1);
    translate([0, 0, h1]) cylinder(r1 = r1 + r3, r2 = r2 + r3,  h = h2);
}

module standoffneg(r1 = defScrewHeadRad, r2 = defScrewRad, r3 = 1.5, h1 = defScrewHeadDepth, h2 = defScrewDepth) {
    translate([0, 0, -fudge]) bolthole(r1 = r1, r2 = r2, h1 = h1 + fudge, h2 = h2 + fudge, membrane = defLayer);
}

/**
 * Make a set of standoffs for mounting a board.
 * @param r1 head (widest) radius
 * @param r2 screw (narrowest) radius
 * @param r3 standoff thickness
 * @param h1 depth of screw
 * @param h2 depth of screw head to end (i.e. total length = h1+h2)
 * @param x distance to centers in x axis
 * @param y distance to centers in y axis
 */
module standoffspos(r1 = defScrewHeadRad, r2 = defScrewRad, r3 = 1.5, h1 = defScrewHeadDepth, h2 = defScrewDepth, x = 20, y = 20) {
    for (xi = [-0.5:0.5]) {
        for (yi = [-0.5:0.5]) {
            translate([xi * x, yi * y, 0]) {
                standoffpos(r1, r2, r3, h1, h2);
            }
        }
    }
}
/**
 * Make a set of standoffs for mounting a board.
 * @param r1 head (widest) radius
 * @param r2 screw (narrowest) radius
 * @param r3 standoff thickness
 * @param h1 depth of screw
 * @param h2 depth of screw head to end (i.e. total length = h1+h2)
 * @param x distance to centers in x axis
 * @param y distance to centers in y axis
 */
module standoffsneg(r1=defScrewHeadRad, r2=defScrewRad, r3 = 1.5, h1=defScrewHeadDepth, h2=defScrewDepth, x = 20, y = 20) {
    for (xi = [-0.5:0.5]) {
        for (yi = [-0.5:0.5]) {
            translate([xi * x, yi * y, 0]) standoffneg(r1, r2, r3, h1, h2);
        }
    }
}
module standoffs(r1=defScrewHeadRad, r2=defScrewRad, r3 = 1.5, h1=defScrewHeadDepth, h2=defScrewDepth, l = 0.3, x = 20, y = 20) {
    difference() {
        standoffspos(r1 = r1, r2 = r2, r3 = r3, h1 = h1, h2 = h2, x = x, y = y);
        standoffsneg(r1 = r1, r2 = r2, r3 = r3, h1 = h1, h2 = h2, x = x, y = y);
    }
}

/**
 * Make a slot with rounded ends.
 * @param r radius of slot
 * @param l length of slot, not including radius
 */
module slot2d(r = 3, l = 20) {
    hull() {
        translate([-l / 2, 0, 0]) polyhole2d(r = r);
        translate([l / 2, 0, 0]) polyhole2d(r = r);
    }
    //cube([l, 2 * r, h], center = true);
}

/**
 * Make a slot with rounded ends.
 * @param r radius of slot
 * @param h height of slot
 * @param l length of slot, not including radius
 */
module slot(r = 3, h = 5, l = 20) {
    translate([0, 0, -h/2]) linear_extrude(height = h) slot2d(r, l);
    //cube([l, 2 * r, h], center = true);
}

/**
 * Make a cube which has corners rounded in x and y
 * @param size vector containing cube dimensions
 * @param r radius of rounding
 * @param center whether to center the cube
 */
module roundedcube(size, r = 1, center = false) {
    //#cube(size, center = center);
    translate([0, 0, center ? -size[2] / 2 : 0]) linear_extrude(height = size[2]) roundedsquare(size, r, center = center);
}

/**
 * Make a cube which has corners rounded in x, y, and z
 * @param size vector containing cube dimensions
 * @param r radius of rounding
 * @param center whether to center the cube
 */
module roundedcube3(size, r = 1, center = false) {
    //#cube(size, center = center);
    if (0) {
        minkowski() {
            translate(center ? 0 : [r, r, r]) cube([size[0] - 2 * r, size[1] - 2 * r, size[2] - 2 * r], center = center);
            sphere(r = r);
        }
    } else {
        translate(center ? 0 : [size[0]/2, size[1]/2, size[2]/2]) hull() {
            for(x=[-1, 1], y=[-1, 1], z=[-1,1]) {
                translate([x* (size[0] / 2 - r), y * (size[1] / 2 - r), z * (size[2] / 2 - r)]) sphere(r = r);
            }
        }
    }
}

module double_cone(h = 1, r = 1, faces = [true, true]) {
    if (faces[0]) {
        cylinder(r1 = 0, r2 = r, h = h);
    }
    if (faces[1]) {
        translate([0, 0, h - fudge]) cylinder(r1 = r, r2 = 0, h = h);
    }
}

/**
 * Like linear_extrude, but with a chamfer of specified height at the top and bottom.
 * @param height total extruded height
 * @param chamfer height of chamfer
 * @param width (optional) width of chamfer, if different from chamfer height
 * @param faces vector for whether to chamfer the bottom / top, respectively,
 * or one of "bottom", "top", "both", or "none".
 * @children 2d shape to extrude
 */
module chamfer_extrude(height = 10, chamfer = 1, width, faces = [true, true], convexity = 3) {
    bottom = is_list(faces) ? faces[0] : (faces == "bottom" || faces == "both");
    top = is_list(faces) ? faces[1] : (faces == "top" || faces == "both");
    chamfer_r = width == undef ? chamfer : width;
    if (bottom || top) {
        total_chamfer = (bottom ? chamfer : 0) + (top ? chamfer : 0);
        translate([0, 0, bottom ? 0 : -chamfer]) minkowski() {
            linear_extrude(height = height - total_chamfer, convexity = convexity) offset(delta = -chamfer_r) children();
            double_cone(h = chamfer, r = chamfer_r, faces = [bottom, top], $fs = 0.2);
        }
    } else {
        linear_extrude(height = height, convexity = convexity) children();
    }
}

/**
 * Make a square which has rounded corners
 * @param size vector containing cube dimensions
 * @param r radius of rounding
 * @param center whether to center the cube
 */
module roundedsquare(size, r = 1, center = false) {
    //#square(size, center = center);
    minkowski() {
        translate(center ? [0, 0, 0] : [r, r]) square([size[0] - 2 * r, size[1] - 2 * r], center = center);
        circle(r = r);
    }
}

/**
 * Make a wedge of a circle
 * @param r radius of rounding
 * @param a angle of wedge, between 0 and 360
 */
module wedge(r = 7, a = 225) {
    if (a <= 180) {
        difference() {
            circle(r = r);
            translate([-fudge, -r-fudge]) square([r*2+0.1, r*2+0.1], center=true);
            rotate([0,0,a]) translate([-fudge, r+fudge]) square([r*2+0.1, r*2+0.1], center=true);
        }
    }
    if (a > 180) {
        difference() {
            circle(r = r);
            rotate([0,0,a]) wedge(r = r * 1.1, a = 360 - a);
        }
    }
}

/**
 * Make a thin-walled box section tube.
 * @param size outside dimensions
 * @param thickness wall thickness
 */
module box2d(size = [10, 5], thickness = 1) {
    difference() {
        square(size);
        translate([thickness, thickness]) square([size[0] - thickness * 2, size[1] - thickness * 2]);
    }
}
/**
 * Make a thin-walled box section tube.
 * @param size outside dimensions
 * @param thickness wall thickness
 */
module box(size = [10, 5, 5], thickness = 1) {
    linear_extrude(height = size[2]) box2d([size[0],size[1]], thickness);
}

/**
 * Make a thin-walled circle.
 * @param r outside radius
 * @param thickness wall thickness
 * @param a angle of ring, if only a segment of ring is required
 */
module ring(r = 5, thickness = 1, a = 360) {
    difference() {
        if (a < 360) {
            wedge(r = r, a = a);
        } else { 
            circle(r);
        }
        polyhole2d(r - thickness);
    }
}


// These functions for barbell by Greg Frost
function triangulate(point1, point2, length1, length2) = point1 + length1 * rotated(atan2(point2[1] - point1[1], point2[0] - point1[0]) + angle(distance(point1, point2), length1, length2));
function distance(point1, point2) = norm(point2 - point1);
function angle(a, b, c) = acos((a * a + b * b - c * c) / (2 * a * b)); 
function rotated(a) = [cos(a), sin(a), 0];
/**
 * Make a 2d barbell shape
 * @param x1 2d position of first ball
 * @param x2 2d position of second ball
 * @param r1 radius of first ball 
 * @param r2 radius of second ball 
 * @param r3 radius of top subtracted sculpt
 * @param r4 radius of bottom subtracted sculpt
 */
module barbell(x1, x2, r1, r2, r3, r4) {
    x3 = triangulate(x1, x2, r1 + r3, r2 + r3);
    x4 = triangulate(x2, x1, r2 + r4, r1 + r4);
    render() difference() {
        union() {
            translate(x1) circle(r = r1);
            translate(x2) circle(r = r2);
            polygon(points = [x1, x3, x2, x4]);
        }
        
        translate(x3) circle(r = r3, $fa=5);
        translate(x4) circle(r = r4, $fa=5);
    }
}


// Make a rectangular grid of bars, centered around the origin, used by grill
module bars(thickness = 1.25, gap = 1.75, angle = 0, size = [40, 40]) {
    repeat = thickness + gap;
    //# square(size, center = true);
    numbars = ceil(size[1] / 2 / repeat);
    rotate([0, 0, angle]) for (y = [-numbars * repeat - thickness / 2 : repeat : repeat * numbars]) {
        translate([-size[0] / 2, y]) square([size[0], thickness]);
    }
}

// Make a rectangular grid of hexes, centered around the origin, used by grill
module hexes(r = 2, thickness = 1, size = [40, 40]) {
    cellHeight = r * sin(60);
    cellSideLength = r * cos(60) * 2;
    horizThickness = r - cellSideLength / 2;
    //echo(str("r=",r," t=",thickness," ch=",cellHeight," cs=",cellSideLength," ht=",horizThickness));
    difference() {
        square(size, center = true);
        for (x = [-size[0] / 2 : (r + horizThickness) * 2: size[0] / 2 + r]) {
            for (y = [-size[1] / 2 : cellHeight * 2 : size[1] / 2 + r]) {
                translate([x, y]) circle(r = r - thickness/2, $fn=6);
                translate([x + r + horizThickness, y + cellHeight]) circle(r = r - thickness/2, $fn=6);
            }
        }
    }
}

/**
 * Create a grill suitable for cutting out of a 2d shape.
 * @param delta the width of the margin around the edges of the shape that will not be grilled
 * @param thickness the wall thickness of the grill structure
 * @param angle if set, rotate the grill pattern by this amount
 * @param type the grill type, either "bar" or "hex"
 * @param bounds the maximum size of the child being processed
 * @param offset the offset from origin to center of the child
 * @param center true if the child is centered on the origin
 * @children 2d shape to install a grill into
 */
module grill_negative(delta = 3, thickness = 1, angle = 0, type = "bar", bounds = [50, 50], offset = [0, 0], gap = 1.5, r = 3) {
    bounds2 = [max(bounds[0], bounds[1]), max(bounds[0], bounds[1])] * 1.4; // Handle worst case rotation angle
    difference() {
        offset(delta = -delta) children();
        translate(offset) if (type == "bar") {
            bars(thickness = thickness, gap = gap, angle = angle, size = bounds2);
        } else {
            hexes(thickness = thickness, r = r, size = bounds);
        }
    }
}

/**
 * Cut a grill out of a 2d shape.
 * @param delta the width of the margin around the edges of the shape that will not be grilled
 * @param thickness the wall thickness of the grill structure
 * @param angle if set, rotate the grill pattern by this amount
 * @param type the grill type, either "bar" or "hex"
 * @param bounds the maximum size of the child being processed
 * @param offset the offset from origin to center of the child
 * @param center true if the child is centered on the origin
 * @children 2d shape to install a grill into
 */
module grill(delta = 3, thickness = 1, angle = 0, type = "bar", bounds = [50, 50], offset = [0, 0], gap = 1.5, r = 3) {
    difference() {
        children();
        grill_negative(delta, thickness, angle, type, bounds, offset, gap, r)
            children();
    }
}

/**
 * Make a thin-walled cylindrical tube.
 * @param r outside radius
 * @param h height of tubes
 * @param thickness wall thickness
 * @param a angle of ring, if only a segment of ring is required
 */
module tube(r = 5, h = 5, thickness = 1, a = 360, center = false) {
    translate([0, 0, center ? -h / 2 : 0]) linear_extrude(height = h) ring(r, thickness, a);
}

/**
 * Make clips for making a lid fit on a box (use as either positive or negative)
 * @param size x,y dimensions of box
 * @param cliplength length of the clip
 * @param thickness wall thickness
 */
module boxclips(size, cliplength, clipdepth = 3) {
    basex=size[0];
    basey=size[1];
    for (y = [0, basey]) {
        translate([basex/2, y, clipdepth/2]) rotate([45,0,0]) cube([cliplength, clipdepth*0.7, clipdepth*0.7], center=true);
    }
    for (x = [0, basex]) {
        translate([x, basey/2, clipdepth/2]) rotate([0,45,0]) cube([clipdepth*0.7, cliplength, clipdepth*0.7], center=true);
    }
}

/**
 * Make a base which takes a clip on lid
 * @param size outer dimensions of the base
 * @param cliplength length of clips
 * @param clipdepth how deep the clip grips (should be less than Z of size)
 * @param r radius for corner rounding
 */ 
module clipbase(size, cliplength = 10, clipdepth = 3, r = 5) {
    difference() {
        roundedcube(size, r = r);
        boxclips(size, cliplength = cliplength + tolerance * 2, clipdepth = clipdepth);
    }
}

/**
 * Make a lid which clips on to the above base. Uses tolerance to adjust dimensions
 * @param size inner dimensions of the box (not counting base z)
 * @param thickness wall thickness
 * @param cliplength length of clips
 * @param clipdepth how deep the clip grips (should be less than Z of base size)
 * @param r radius for corner rounding
 */ 
module cliplid(size, thickness = 3, cliplength = 10, clipdepth = 3, r = 5) {
    difference() {
        translate([-thickness, -thickness]) roundedcube([size[0] + 2 * thickness, size[1] + 2 * thickness, size[2] + thickness], r = r);
        translate([-tolerance, -tolerance, -fudge]) roundedcube([size[0] + tolerance * 2, size[1] + tolerance * 2, size[2]], r = r);
    }
    translate([-tolerance, -tolerance, 0]) boxclips([size[0] + tolerance * 2, size[1] + tolerance * 2], cliplength = cliplength, clipdepth = clipdepth);
}


module utildemo() {
    translate([5,5]) roundedcube(size=[40,15,10], r=3, $fn = 16);
    translate([5,25]) roundedcube3(size=[40,15,10], r=3, $fn = 16);
    translate([5,-15,0]) chamfer_extrude(height = 10, chamfer = 2, $fn = 16) square(size=[40,15]);
    translate([45,-15,0]) chamfer_extrude(height = 10, chamfer = 2, faces = "bottom", $fn = 16) square(size=[40,15]);
    translate([5,-35,0]) roundedsquare(size=[40,15], r=3);
    translate([-20,5,0]) slot();
    translate([-20,15,0]) wedge();
    translate([-10,-15,0]) bolthole(membrane=defLayer);
    translate([-20,-15,0]) countersink();
    translate([-10,-25,0]) box2d();
    translate([-20,-25,0]) ring();
    translate([-10,-35,0]) box();
    translate([-20,-35,0]) tube();
    translate([-55,-30,0]) standoffs();
}
utildemo();
//test_polyhole();
