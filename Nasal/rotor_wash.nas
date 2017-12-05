# Thorsten Renk, modified by HHS

##########################################
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

var blade_incidence1 = getprop("rotors/main/blade[0]/incidence-deg") or 0;
var blade_incidence2 = getprop("rotors/main/blade[1]/incidence-deg") or 0;
var blade_incidence3 = getprop("rotors/main/blade[2]/incidence-deg") or 0;
var blade_incidence4 = getprop("rotors/main/blade[3]/incidence-deg") or 0;

var blade_incidence_av = ((blade_incidence1 + blade_incidence2 + blade_incidence3 + blade_incidence4)/4);

var strength = 50/alt;
if (strength > 1.0) {strength = 1.0;}
strength = strength * (rpm_factor* (blade_incidence_av/17)) +0.1 ;

setprop("/environment/aircraft-effects/wash-strength", strength);
setprop("/rotors/main/blade-incidence", blade_incidence_av);

settimer (wash_loop, 0.0);
};

wash_loop();

