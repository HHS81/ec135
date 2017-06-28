# Thorsten Renk, modified by HHS

##########################################
# Preflight control surface check: elevator
##########################################
var wash_loop = func {

var vpos = geo.viewer_position();
var apos = geo.aircraft_position();

var lat_to_m = 110952.0;
var lon_to_m = math.cos(apos.lat()*math.pi/180.0) * lat_to_m;

var alt = getprop("/position/altitude-agl-ft");

var delta_x = (apos.lat() - vpos.lat()) * lat_to_m;
var delta_y = -(apos.lon() - vpos.lon()) * lon_to_m;

setprop("/environment/aircraft-effects/wash-x", delta_x);
setprop("/environment/aircraft-effects/wash-y", delta_y);

var rpm_factor = getprop("rotors/main/rpm")/395.0;


var strength = 37.5/alt;
if (strength > 1.0) {strength = 1.0;}
strength = strength * rpm_factor;

setprop("/environment/aircraft-effects/wash-strength", strength);

settimer (wash_loop, 0.0);
};

wash_loop();

