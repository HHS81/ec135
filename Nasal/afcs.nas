#### H135 AFCS ####
#### by H. Schulz  ####
###

	#This file is part of FlightGear, the free flight simulator
	#http://www.flightgear.org/

	#Copyright (C) 2018 Heiko Schulz, Heiko.H.Schulz@gmx.net

	#This program is free software; you can redistribute it and/or
	#modify it under the terms of the GNU General Public License as
	#published by the Free Software Foundation; either version 2 of the
	#License, or (at your option) any later version.

	#This program is distributed in the hope that it will be useful, but
	#WITHOUT ANY WARRANTY; without even the implied warranty of
	#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	#General Public License for more details.
	

###
# init
var listenerAFCSInitFunc = func {
	# do initializations of new properties

setprop("/autopilot/afcs/control/alt-mode", 0);
setprop("/autopilot/afcs/control/speed-mode", 0);
setprop("/autopilot/afcs/control/heading-mode", 0);
setprop("/autopilot/afcs/engaged", 0);
setprop("/autopilot/afcs/control/ap1", 0);
setprop("/autopilot/afcs/control/ap2", 0);



	
}
setlistener("sim/signals/fdm-initialized", listenerAFCSInitFunc);
###

var afcs_action = func{



var ap1 = getprop("/autopilot/afcs/control/ap1") or 0;
var ap2 = getprop("/autopilot/afcs/control/ap2") or 0;
var ias = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") or 0;
var afcs = getprop("/autopilot/afcs/engaged") or 0;
var swt = getprop("/autopilot/afcs/internal/swt") or 0;

var altmode = getprop("/autopilot/afcs/control/alt-mode") or 0;
var speedmode = getprop("/autopilot/afcs/control/speed-mode") or 0;
var headmode = getprop("/autopilot/afcs/control/heading-mode") or 0;
var atrim = getprop("/autopilot/afcs/control/atrim") or 0;

##


if (atrim >0){
setprop("/autopilot/afcs/internal/atrim", 1);
}else{
setprop("/autopilot/afcs/internal/atrim", 0);
}

if ((ap1 > 0) and (afcs > 0)){
setprop("/autopilot/afcs/internal/ap1", 1);
setprop("/autopilot/afcs/internal/bkup", 1);
}else{
setprop("/autopilot/afcs/internal/ap1", 0);
setprop("/autopilot/afcs/control/ap1", 0);
}

if ((ap2 > 0) and (afcs > 0)){
setprop("/autopilot/afcs/internal/ap2", 1);
setprop("/autopilot/afcs/internal/bkup", 1);
}else{
setprop("/autopilot/afcs/internal/ap2", 0);
setprop("/autopilot/afcs/control/ap2", 0);
}


##
if  ((ap1 > 0) or (ap2 > 0)){

if (altmode == 0) {
setprop("/autopilot/afcs/locks/altitude","");
}

if (altmode == 1) {
setprop("/autopilot/afcs/locks/altitude", "crht-hold");
}

# aka altitude-aquire
if (altmode == 2) { 
setprop("/autopilot/afcs/locks/altitude", "altitude-hold");
setprop("/autopilot/afcs/internal/altitude-armed", 1);
}

if (altmode == 3) {
setprop("/autopilot/afcs/locks/altitude", "altitude-hold");
setprop("/autopilot/afcs/internal/altitude-armed", 0);
}

if ((altmode == 4) and (swt < 1)){
setprop("/autopilot/afcs/locks/altitude", "fpa-hold");
}

if ((altmode == 4) and (swt > 0)){
setprop("/autopilot/afcs/locks/altitude", "vs-hold");
}


if (speedmode == 1) {
setprop("/autopilot/afcs/locks/speed", "ias-hold");
}

if (speedmode == 0) {
setprop("/autopilot/afcs/locks/speed", "");
}

if ((headmode == 1) and (swt < 1)){
setprop("/autopilot/afcs/locks/heading", "trk-hold");
}

if ((headmode == 1) and (swt > 0)){
setprop("/autopilot/afcs/locks/heading", "heading-hold");
}

if (headmode == 0){
setprop("/autopilot/afcs/locks/heading", "");
}


}elsif  ((ap1 < 1) or (ap2 < 1)){
setprop("/autopilot/afcs/internal/altitude-armed", 0);
setprop("/autopilot/afcs/control/alt-mode", 0);
setprop("/autopilot/afcs/control/speed-mode", 0);
setprop("/autopilot/afcs/control/heading-mode", 0);
setprop("/autopilot/afcs/locks/altitude", "");
setprop("/autopilot/afcs/locks/heading", "");
setprop("/autopilot/afcs/locks/speed", "");
setprop("/autopilot/afcs/internal/bkup", 0);
}



##
if ((ap1 == 1) or (ap2 == 1))  {
var my_vs = getprop("/autopilot/internal/vert-speed-fpm") or 0;
my_vs =  int(my_vs * 0.01);
my_vs *= 100;
if(my_vs>2200)my_vs=2200;
if(my_vs<-2200)my_vs=-2200;
setprop("autopilot/afcs/settings/fpm",my_vs);
}

if ((ap1 == 1") or (ap2 == 1))   {
var vsw = getprop("autopilot/afcs/settings/fpm") or 0;
vsw = int(vsw * 0.01);
vsw *= 100;
setprop("autopilot/afcs/settings/fpm",vsw);
}

##

if ((ap1 == "true") or (ap2 == "true"))   {
var my_vfps = getprop("/autopilot/afcs/internal/vBody-fps") or 0;
my_vfps =  int(my_vfps * 10);
my_vfps *= 0.1;
setprop("/autopilot/afcs/internal/vBody-fps",my_vfps);

}
if ((ap1 == "true") or (ap2 == "true"))  {
var svps = getprop("/autopilot/afcs/internal/vBody-fps") or 0;
svps = int(svps * 10);
svps *= 0.1;
setprop("/autopilot/afcs/internal/vBody-fps",svps);
}

##

if ((ap1 == "true") or (ap2 == "true"))  {
var my_ufps = getprop("/autopilot/afcs/internal/uBody-fps") or 0;
my_ufps =  int(my_ufps * 10);
my_ufps *= 0.1;
setprop("/autopilot/afcs/internal/uBody-fps",my_ufps);
}

if ((ap1 == "true") or (ap2 == "true"))  {
var sups = getprop("/autopilot/afcs/internal/uBody-fps") or 0;
sups= int(sups * 10);
sups *= 0.1;
setprop("/autopilot/afcs/internal/uBody-fps",sups);
}

##

if (ias < 30){
			var kpHHHold = 1;
			interpolate("/autopilot/afcs/internal/kpHHHold", kpHHHold, 5 );
			}else{
			interpolate("/autopilot/afcs/internal/kpHHHold", 0, 1 );
			}


if (ias > 30){
			var kpSS = -0.5;
			interpolate("/autopilot/afcs/internal/kpSS", kpSS, 1 );
			}else{
			interpolate("/autopilot/afcs/internal/kpSS", 0, 1 );
			}
		

if (ias < 30){
			var kpHHHold2 = -0.125;
			interpolate("/autopilot/afcs/internal/kpHHHold2", kpHHHold2, 1 );
			}else{
			interpolate("/autopilot/afcs/internal/kpHHHold2", 0, 1 );
			}
			
##
#fpa
##
        var TAS = getprop("/velocities/groundspeed-kt") or 0; 
       var VS = getprop("velocities/vertical-speed-fps") or 0;
        var TASft = TAS * NM2M / 3600; 
    	var VSft= (VS * FT2M);  

if ((ap1 == "true") or (ap2 == "true")) {
	   var FPangle = math.atan2(VSft, TASft) * R2D;
            setprop("autopilot/afcs/internal/fpa", (FPangle * -1));
	}

settimer(afcs_action, 0.01);
}
afcs_action();
  

