// When including this in your project, consider commenting these
// and defining them instead in your base project file
$airfoil_fn = 25;
$close_airfoils = true;
$debug = false;

// https://en.wikipedia.org/wiki/NACA_airfoil

function foil_y(x, c, t) =
  // NACA symmetrical airfoil formula
  (5 * t * c) * ( (0.2969 * sqrt(x / c)) - (0.1260 * (x / c)) - (0.3516 * pow((x / c), 2)) + (0.2843 * pow((x / c), 3)) - ( ($close_airfoils ? 0.1036 : 0.1015) * pow((x / c), 4)));
function camber(x, c, m, p) =
  (
    x <= (p * c) ?
      ( ( (c * m) / pow(p, 2)) * ( (2 * p * (x / c)) - pow((x / c), 2)))
    : ( ( (c * m) / pow((1 - p), 2)) * ( (1 - (2 * p)) + (2 * p * (x / c)) - pow((x / c), 2)))
  );
function theta(x, c, m, p) =
  (
    x <= (p * c) ?
      atan(( (m) / pow(p, 2)) * (p - (x / c)))
    : atan(( (m) / pow((1 - p), 2)) * (p - (x / c)))
  );
function camber_y(x, c, t, m, p, upper = true) =
  (
    upper == true ?
      (camber(x, c, m, p) + (foil_y(x, c, t) * cos(theta(x, c, m, p))))
    : (camber(x, c, m, p) - (foil_y(x, c, t) * cos(theta(x, c, m, p))))
  );
function camber_x(x, c, t, m, p, upper = true) =
  (
    upper == true ?
      (x - (foil_y(x, c, t) * sin(theta(x, c, m, p))))
    : (x + (foil_y(x, c, t) * sin(theta(x, c, m, p))))
  );

module validate(spec, res_bias = 2, print = $debug) {
  if (print == true) { echo(str("Validating spec ", spec)); }
  assert(is_list(spec) && len(spec) == 2, "Airfoils must be specified as [chord, naca]");
  assert(is_num(spec[0]) && 0 < spec[0], str("Invalid chord \"", spec[0], "\""));
  assert(is_num(spec[1]) && 0 < spec[1] && spec[1] <= 9999, str("Invalid NACA specification \"", spec[1], "\""));
  assert(is_num(res_bias) && 1 <= res_bias && res_bias <= spec[0], str("Invalid resolution bias \"", res_bias, "\" (min: 1, max: ", spec[0], ")"));
}

module airfoil_poly(c = 100, naca = 0015, raw = false, res_bias = 2) {

  validate([c, raw == true ? 0 : naca], res_bias);
  $airfoil_fn = !is_undef($airfoil_fn) ? $airfoil_fn : 25;
  $close_airfoils = !is_undef($close_airfoils) ? $close_airfoils : true;
  res = c / $airfoil_fn; // Resolution of foil poly

  // Maximum camber:chord
  m = (raw == true) ? raw[0] : ( (floor(( ( (naca - (naca % 100)) / 1000) )) / 100) );
  // Distance of maximum camber from the airfoil leading edge in tenths of the chord
  p = (raw == true) ? raw[1] : ( ( ( (naca - (naca % 100)) / 100) % 10) / 10);
  // Establish thickness/length ratio
  t = (raw == true) ? raw[2] : ( (naca % 100) / 100);

  // Points have to be generated with or without camber, depending.
  res_map_u = [for (x = [0:res:c]) x * min(1, x / (c / res_bias))];
  if ($debug == true) { echo(res_map_u=res_map_u); }
  points_u =
    (m == 0 || p == 0) ?
      [for (i = res_map_u) let (x = i, y = foil_y(i, c, t)) [x, y]]
    : [for (i = res_map_u) let (x = camber_x(i, c, t, m, p), y = camber_y(i, c, t, m, p)) [x, y]];

  res_map_l = [for (x = [c:-res:0]) x * min(1, x / (c / res_bias))];
  if ($debug == true) { echo(res_map_l=res_map_l); }
  points_l =
    (m == 0 || p == 0) ?
      [for (i = res_map_l) let (x = i, y = foil_y(i, c, t) * -1) [x, y]]
    : [for (i = res_map_l) let (x = camber_x(i, c, t, m, p, upper=false), y = camber_y(i, c, t, m, p, upper=false)) [x, y]];

  if ($debug == true) {
    echo(points_u=points_u);
    echo(points_l=points_l);
  }
  polygon(concat(points_u, points_l)); // Draw poly
}

// Todo: Wings, w/angles

// Airfoil definition = [c,naca]
module airfoil_simple_wing(airfoils = false, wing_angle = [0, 0], wing_length = 1000) {

  if (airfoils != false) {
    if (!is_list(airfoils[0])) {
      validate(airfoils, print=false);
      hull() {
        linear_extrude(0.1)
          airfoil_poly(airfoils[0], airfoils[1]);

        translate([(sin(wing_angle[0]) * wing_length), (sin(wing_angle[1]) * wing_length), wing_length])
          linear_extrude(0.1)
            airfoil_poly(airfoils[0], airfoils[1]);
      }
    } else {
      if ($debug == true) { echo(wing_length=wing_length); }
      union() {
        segments = len(airfoils) - 1;
        segment_length = wing_length / segments;
        for (i = [1:segments]) {
          validate(airfoils[i - 1], print=false);
          if ($debug == true) { echo(str("segment from ", segment_length * (i - 1), " to ", segment_length * i)); }
          hull() {
            translate(
              [
                (sin(wing_angle[0]) * wing_length * (i - 1) / segments),
                (sin(wing_angle[1]) * wing_length * (i - 1) / segments),
                segment_length * (i - 1),
              ]
            )
              linear_extrude(0.1)
                airfoil_poly(airfoils[ (i - 1) ][0], airfoils[ (i - 1) ][1]);

            translate(
              [
                (sin(wing_angle[0]) * wing_length * i / segments),
                (sin(wing_angle[1]) * wing_length * i / segments),
                segment_length * i,
              ]
            )
              linear_extrude(0.1)
                airfoil_poly(airfoils[i][0], airfoils[i][1]);
          }
        }
      }
    }
  } else {
    echo(
      "No Airfoils defined! Airfoils should be a set of `[chord, naca]`. Specify one for a uniform wing, two or more for compound wing.
      If specifying only one, do not put it in a set/vector. Multiple airfoils will be spaced evenly along the wing length."
    );
  }
}

module airfoil_help() {
  echo(
    "\n
    # Parametric Airfoil and Wing Generator v0.2\n
    For a brief overview of the math and specifications used, see https://en.wikipedia.org/wiki/NACA_airfoil\n
   \n
    ## Globals:\n
    - `$close_airfoils`: Defines whether you want the back of your air foils closed, or if you want them open (default: false)\n
    - `$airfoil_fn`: number of sides for your airfoil. (default: 100)\n
   \n
    ### `airfoil_poly` args:\n
    - `c`: Chord length, this is the chord length of your airfoil. (default: 100)\n
    - `naca`: The NACA 4-digit specification for your airfoil. (default: 0015)\n
    - `raw`: Overrides the NACA code with direct ratios. Provide in the same order as the NACA digits. (e.g NACA 4123 becomes raw `[.4,.1,.23]`)\n
    - `res_bias`: Resolution bias towards forward edge for cleaner curve (lower = more bias).
      - Careful, this will remove resolution from trailing edge, but only really noticible with camber positions greater than 70% (naca > x7xx).

  No bias = chord (var c)
   \n
    ### `airfoil_simple_wing` args:\n
    - `airfoils`: Airfoils should be a set of `[chord, naca]`. Specify one for a uniform wing, two or more in a vector for compound wing. (required)\n
      - If specifying only one, do not put it in a set/vector. Multiple airfoils will be spaced evenly along the wing length.\n
    - `wing_angle`: A set of angles in the form `[sweep, slope]` (optional, default=[0,0])\n
    - `wing_length`: Length of the wing (optional, default=1000)"
  );
}
// airfoil_help();
// translate([0,0,100]) airfoil_poly();
// airfoil_simple_wing(airfoils=[[100,0015],[200,2414],[100,0015],[200,2414],[100,0015]], wing_angle=[20,-20]);
