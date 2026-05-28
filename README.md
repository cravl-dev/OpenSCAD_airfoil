# OpenSCAD_airfoil

## Parametric Airfoil and Wing Generator v0.1

Homepage: https://github.com/ErroneousBosch/OpenSCAD_airfoil

For a brief overview of the math and specifications used, see https://en.wikipedia.org/wiki/NACA_airfoil

## Globals:

**`$close_airfoils`**  _(default: `false`)_<br>Defines whether you want the back of your airfoils closed, or if you want them open.

**`$airfoil_fn`**  _(default: `25`)_<br>Number of sides for your airfoil.

## `airfoil_poly` parameters:

This function generates a 2D polygon of an airfoil, using the following variables.

**`c`**  _(default: `100`)_<br>
The chord length of your airfoil.

**`naca`**  _(default: `0015`)_<br>
The NACA 4-digit specification for your airfoil.

**`raw`**<br>
Overrides the NACA code with direct ratios. Provide in the same order as the NACA digits. (e.g NACA 4123 becomes raw `[.4,.1,.23]`)

**`res_bias`** _(min: `1`, max: `c`, default: `2`)_<br>
Resolution bias towards forward edge for cleaner curve. Lower = more bias.

> [!NOTE]
> This will remove resolution from trailing edge, but is only really noticible with camber positions greater than 70% (naca > x7xx). The default is probably fine for 95% of uses.

## `airfoil_simple_wing` parameters:

This will generate a simple wing based on one or more supplied airfoils. Each set of airfoils is an individual shape, allowing for very complex variation along the wing.

**`airfoils`**<br>
Two modes:

1. _Single airfoil_: Specifying a single airfoil will generate a uniform wing based on that airfoil. You can specify the airfoil as a set (vector) of `[chord, naca]`.

2. _Multiple airfoils_: Specify a set (vector) of airfoils. Individual airfoils are specified the same as a single airfoil (see above). These airfoils will be spaced evenly along the wing length.

**`wing_angle`** _(optional, default=`[0,0]`)_<br>
A set of angles, \[sweep,slope\]. Sweep is along the x axis, slope along the y axis.

**`wing_length`** _(optional, default=`1000`)_<br>
Length of the wing.
