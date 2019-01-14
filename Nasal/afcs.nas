#### H135 AFCS ####
#### by H. Schulz  ####
###

	#This file is part of FlightGear, the free flight simulator
	#http://www.flightgear.org/

	#Copyright (C) 2018/2019 Heiko Schulz, Heiko.H.Schulz@gmx.net

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
setprop("/autopilot/afcs/control/speed-mode-TEST", 0);
setprop("/autopilot/afcs/control/heading-mode", 0);
setprop("/autopilot/afcs/engaged", 0);
setprop("/autopilot/afcs/control/ap1", 0);
setprop("/autopilot/afcs/control/ap2", 0);
setprop("/autopilot/afcs/control/gtc", 0);
setprop("/autopilot/afcs/control/navsource-couple", 0);
setprop("/autopilot/afcs/internal/nav1-armed", 0);
setprop("/autopilot/afcs/internal/target-climb-rate-fps", 0);
setprop("/autopilot/afcs/settings/sel-target-altitude-ft", 0);
setprop("/controls/flight/collective", 0);
setprop("/autopilot/afcs/internal/gs-armed", 0);
setprop("/autopilot/afcs/internal/att-mode", 0);
setprop("/autopilot/internal/use-collective-for-alt", 1);         ## Helionix uses it through all speed ranges. So use this property for collective axis failure by setting it false
setprop("/autopilot/afcs/control/ga", 0);



}
setlistener("sim/signals/fdm-initialized", listenerAFCSInitFunc);
###

var afcs_action = func{



var ap1 = getprop("/autopilot/afcs/control/ap1") or 0;
var ap2 = getprop("/autopilot/afcs/control/ap2") or 0;
var ias = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") or 0;
var afcs = getprop("/autopilot/afcs/engaged") or 0; #powered on
var swt = getprop("/autopilot/afcs/internal/swt") or 0;
var gtcc = getprop("/autopilot/afcs/control/gtc") or 0;
var ga = getprop("/autopilot/afcs/control/ga") or 0;
var ucfa = getprop("/autopilot/internal/use-collective-for-alt") or 0;

var altmode = getprop("/autopilot/afcs/control/alt-mode") or 0;
var ap1engaged = getprop("/autopilot/afcs/internal/ap1") or 0;
var ap2engaged = getprop("/autopilot/afcs/internal/ap2") or 0;
var speedmode = getprop("/autopilot/afcs/control/speed-mode") or 0;
var headmode = getprop("/autopilot/afcs/control/heading-mode") or 0;
var navsourcecoupled = getprop("/autopilot/afcs/control/navsource-couple") or 0;
var nav1armed = getprop("/autopilot/afcs/internal/nav1-armed") or 0;
var nav2armed = getprop("/autopilot/afcs/internal/nav2-armed") or 0;
var navsource = getprop("/instrumentation/efis/fnd/navsource") or 0;
var nav1locked = getprop("/autopilot/afcs/locks/heading/nav-1hold") or 0;
##



if ((ap1 > 0) and (afcs > 0)){
setprop("/autopilot/afcs/internal/ap1", 1);
setprop("/autopilot/afcs/internal/bkup", 1);# should make backup-sas work- there is no yet simulated
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

if ( (ap1engaged >0) or (ap2engaged >0)){
setprop("/controls/flight/fcs/switches/sas", 1);
}else{
setprop("/controls/flight/fcs/switches/sas", 0);
}


##
if  ((ap1 > 0) or (ap2 > 0)){

## if ap on and no uppermode is selected switch to att-mode

if ((altmode == 0) and (speedmode == 0) and (headmode == 0)) {
setprop("/autopilot/afcs/internal/att-mode",1);
}else{
setprop("/autopilot/afcs/internal/att-mode",0);
}

##uppermodes

if (altmode < 1) {
setprop("/autopilot/afcs/locks/altitude","");
}

if (altmode == 1) {
setprop("/autopilot/afcs/locks/altitude", "crht-hold");
}

# aka altitude-aquire
if (altmode == 2) { 
setprop("/autopilot/afcs/locks/altitude", "altitude-aquire");
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

if (altmode == 5) {
setprop("/autopilot/afcs/locks/altitude", "gs1-hold");
}

if (altmode == 6) {
setprop("/autopilot/afcs/locks/altitude", "ias-hold");
setprop("/autopilot/afcs/locks/speed", "");
}

if (altmode == 7) {
setprop("/autopilot/afcs/locks/altitude", "GA");
}

if (speedmode < 1)  {
setprop("/autopilot/afcs/locks/speed", "");
}

if ((speedmode == 1) and (ucfa >0)){
setprop("/autopilot/afcs/locks/speed", "ias-hold");
}

if ((speedmode < 1) and (altmode < 1))  {
setprop("/autopilot/afcs/locks/altitude", "");
}

if ((speedmode == 2) or (speedmode == 3)) {
setprop("/autopilot/afcs/locks/speed", "GTC");
}


if ((headmode == 1) and (swt < 1)){
setprop("/autopilot/afcs/locks/heading", "track-hold");
}

if ((headmode == 1) and (swt > 0)){
setprop("/autopilot/afcs/locks/heading", "heading-hold");
}

if (headmode == 0){
setprop("/autopilot/afcs/locks/heading", "");
}



if ((navsourcecoupled > 0) and (navsource == "FMS")){
setprop("/autopilot/afcs/control/heading-mode", 4);
}

if (headmode == 2){
setprop("/autopilot/afcs/locks/heading", "nav1-hold");
}

if (headmode == 3){
setprop("/autopilot/afcs/locks/heading", "nav2-hold");
}

if (headmode == 4){
setprop("/autopilot/afcs/locks/heading", "true-heading-hold");
}


} elsif ((ap1 < 1) or (ap2 < 1)){
setprop("/autopilot/afcs/internal/altitude-armed", 0);
setprop("/autopilot/afcs/control/alt-mode", 0);
setprop("/autopilot/afcs/control/speed-mode", 0);
setprop("/autopilot/afcs/control/heading-mode", 0);
setprop("/autopilot/afcs/locks/altitude", "");
setprop("/autopilot/afcs/locks/heading", "");
setprop("/autopilot/afcs/locks/speed", "");
setprop("/autopilot/afcs/internal/bkup", 0);
setprop("/autopilot/afcs/control/navsource-couple", 0);
setprop("/autopilot/afcs/control/ga", 0);
#setprop("/autopilot/afcs/timer/rescue-double-click-timer-sec", 0);
setprop("/autopilot/afcs/control/rescue-double-click", 0);
#setprop("/autopilot/afcs/timer/double-click-btn", 0);
#setprop("/autopilot/afcs/timer/rescue-double-click-last-settime", 0);
}


##
#GTC.H Mode: some sources says that it will also put the heli into a zero-speed hover from any speed - let`s simulate this. 
##

if (speedmode == 3){ 
setprop("/autopilot/afcs/settings/target-speed-kt", 0);
setprop("/autopilot/afcs/internal/drift-u-kt", 0);
}

##
#GTC= low speed IAS Hold Mode?? -  switch to it at speed below 30ktn
##

##To-Do: Bug fixing:  let disengage the mode below 30ktn like the switch fpa/vs

if ( (speedmode == 1)  and (getprop("instrumentation/airspeed-indicator/indicated-speed-kt") < 30) ){
setprop("/autopilot/afcs/control/speed-mode", 2);
}elsif ( (speedmode == 2)  and (getprop("instrumentation/airspeed-indicator/indicated-speed-kt") > 30) ){
setprop("/autopilot/afcs/control/speed-mode", 1);
}

if ( (speedmode == 3)  and (getprop("instrumentation/airspeed-indicator/indicated-speed-kt") < 30) ){
setprop("/autopilot/afcs/control/speed-mode", 2);
}elsif ( (speedmode == 3)  and (getprop("instrumentation/airspeed-indicator/indicated-speed-kt") > 30) ){
setprop("/autopilot/afcs/control/speed-mode", 1);
}

## 

##
##Rescue/ Maria Help Button - AFCS Hat switch double-click - 
## According some sources it engages AP, and put on present heading, speed and probably altitude. Some other sources say, that it will need GTC/GTC.H to keep altitude, some says that it will also put the heli into a zero-speed hover. 
##

var rescuebtn = getprop("/autopilot/afcs/timer/rescue-btn-double-clicked") or 0;
var timer = getprop("/autopilot/afcs/timer/rescue-double-click-timer-sec") or 0;
var ra = getprop("/instrumentation/radar-altimeter/radar-altitude-ft") or 0;

if (rescuebtn >0){
setprop("/autopilot/afcs/control/ap1", 1);
setprop("/autopilot/afcs/control/ap2", 1);
setprop("/autopilot/afcs/control/alt-mode", 3);
setprop("/autopilot/afcs/control/speed-mode", 1);
setprop("/autopilot/afcs/control/heading-mode", 1);
setprop("/controls/flight/force_trim_release", "false");
}

if (timer >1){
setprop("/autopilot/afcs/control/rescue-double-click", 0); #reset
}


##
##True Heading Hold/ FMS
##

if ((navsourcecoupled > 0) and (navsource == "FMS")){
setprop("/autopilot/afcs/control/heading-mode", 4);
}


##
##NAV1/ LOC Mode 
##

if ((navsourcecoupled > 0) and (navsource == 0)){
setprop("/autopilot/afcs/internal/nav1-armed", 1);
setprop("/autopilot/afcs/internal/nav2-armed", 0);
}elsif ((navsourcecoupled > 0) and (navsource == "NAV2")){
setprop("/autopilot/afcs/internal/nav1-armed", 0);
setprop("/autopilot/afcs/internal/nav2-armed", 1);
}else{
setprop("/autopilot/afcs/internal/nav1-armed", 0);
setprop("/autopilot/afcs/internal/nav2-armed", 0);
}

var interceptionangle = getprop("/autopilot/afcs/internal/intercept-heading-deg") or 0;
var dfl = getprop("instrumentation/nav/heading-needle-deflection") or 0;
var navloc = getprop("instrumentation/nav/nav-loc") or 0;
var navir = getprop("instrumentation/nav/nav-in-range") or 0;


if ((interceptionangle >45) and (navloc < 1)){
pdfl = 4.52;
mdfl = -4.52;
}else{
pdfl = 1.33;
mdfl = -1.33;
}

if ((interceptionangle >25) and (navloc > 0)){
pdfl = 9.9;
mdfl = -9.9;
}else{
pdfl = 5;
mdfl = -5;
}

if ((headmode == 1) and (nav1armed > 0) )  {
if ((dfl < pdfl) and (dfl >mdfl)){
setprop("/autopilot/afcs/control/heading-mode", 2);
setprop("/autopilot/afcs/internal/nav1-armed", 0);
}else{
setprop("/autopilot/afcs/control/heading-mode", 1);
}
}elsif ((headmode == 2) and (navsourcecoupled < 1)) {
setprop("/autopilot/afcs/control/heading-mode", 1);
}


if ((headmode == 1) and (nav2armed > 0) )  {
if ((dfl < pdfl) and (dfl >mdfl)){
setprop("/autopilot/afcs/control/heading-mode", 3);
setprop("/autopilot/afcs/internal/nav1-armed", 0);
}else{
setprop("/autopilot/afcs/control/heading-mode", 1);
}
}elsif ((headmode == 3) and (navsourcecoupled < 1)) {
setprop("/autopilot/afcs/control/heading-mode", 1);
}

##
##GS1 hold
##

var loc1locked = getprop("/autopilot/afcs/locks") or 0;
var loc2locked = getprop("/autopilot/afcs/locks") or 0;
var gsroc = getprop("instrumentation/nav/gs-rate-of-climb") or 0;
var gs = getprop("instrumentation/nav/gs-in-range") or 0;
var gsn = getprop("instrumentation/nav/gs-needle-deflection") or 0;
var gsarmed = getprop("/autopilot/afcs/internal/gs-armed") or 0;
var ra = getprop("/instrumentation/radar-altimeter/radar-altitude-ft") or 0;

if ((headmode == 2) or (headmode == 3)) {
if ( (gs > 0) and ((gsn < 2.2) and (gsn >-2.2)) ){
setprop("/autopilot/afcs/internal/gs-armed", 1);
}else{
setprop("/autopilot/afcs/internal/gs-armed", 0);
}


if ( (gsarmed >0) and ((gsn < 0.5) and (gsn >-0.2)) )  {
setprop("/autopilot/afcs/control/alt-mode", 5);
setprop("/autopilot/afcs/internal/target-climb-rate-fps",gsroc);
}

#replace "65" later with MDA/ DH property value
#if ((altmode == 5) and (ra <65)){
#setprop("/autopilot/afcs/control/alt-mode", 1);
#setprop("/autopilot/afcs/control/heading-mode", 1);
#setprop("/autopilot/afcs/control/navsource-couple", 0);
#}
#}



##

##
## ALT.A to ALT switch
##

var actualalt = getprop ("/instrumentation/altimeter/indicated-altitude-ft") or 0;
var selectedalt = getprop ("autopilot/afcs/settings/sel-target-altitude-ft") or 0;
var alth = getprop ("/autopilot/afcs/locks/altitude") or 0;
var altd = selectedalt - actualalt;
var altarmed = getprop("/autopilot/afcs/internal/altitude-armed") or 0;



if ( ((altmode == 2) and (altarmed > 0)) and ((altd <300) and (altd >-300)) ){
setprop("/autopilot/afcs/control/alt-mode", 3)
}

##

##VS-protection at low height

if ((altmode == 4) and (ra <65)){
setprop("/autopilot/afcs/control/alt-mode", 1);
}

##

##Go-Around Mode
##
var vs = getprop ("/autopilot/internal/vert-speed-fpm") or 0;

if (altmode == 7){
setprop("/autopilot/afcs/internal/target-climb-rate-fps", 16.667);
setprop("/autopilot/afcs/internal/nav1-armed", 0);
setprop("/autopilot/afcs/internal/nav2-armed", 0);
setprop("/autopilot/afcs/control/navsource-couple", 0);
setprop("/autopilot/afcs/control/speed-mode", 1);
}elsif  ((altmode == 7) and (vs > 500)){
setprop("/autopilot/afcs/internal/target-climb-rate-fps", 16.667);
setprop("/autopilot/afcs/internal/nav1-armed", 0);
setprop("/autopilot/afcs/internal/nav2-armed", 0);
setprop("/autopilot/afcs/control/navsource-couple", 0);
setprop("/autopilot/afcs/control/speed-mode", 1);
setprop("/autopilot/afcs/settings/target-speed-kt", 65);
setprop("/autopilot/afcs/internal/drift-u-kt", 65);
}



##

if  ((ap1 > 0) or (ap2 > 0))  {
var vsw = getprop("autopilot/afcs/settings/fpm") or 0;
vsw = int(vsw * 0.01);
vsw *= 100;
setprop("autopilot/afcs/settings/fpm",vsw);
}


if  ((ap1 > 0) or (ap2 > 0)) {
var my_vfps = getprop("/autopilot/afcs/internal/drift-v-kt") or 0;
my_vfps =  int(my_vfps * 10);
my_vfps *= 0.1;
setprop("/autopilot/afcs/internal/drift-v-kt",my_vfps);
}

if  ((ap1 > 0) or (ap2 > 0))  {
var svps = getprop("/autopilot/afcs/internal/drift-v-kt") or 0;
svps = int(svps * 10);
svps *= 0.1;
setprop("/autopilot/afcs/internal/drift-v-kt",svps);
}

##

if  ((ap1 > 0) or (ap2 > 0))  {
var my_ufps = getprop("/autopilot/afcs/internal/drift-u-kt") or 0;
my_ufps =  int(my_ufps * 10);
my_ufps *= 0.1;
setprop("/autopilot/afcs/internal/drift-u-kt",my_ufps);
}

if  ((ap1 > 0) or (ap2 > 0))  {
var sups = getprop("/autopilot/afcs/internal/drift-u-kt") or 0;
sups= int(sups * 10);
sups *= 0.1;
setprop("/autopilot/afcs/internal/drift-u-kt",sups);
}

##

if  ((ap1 > 0) or (ap2 > 0))  {
var my_alt = getprop("/autopilot/afcs/settings/sel-target-altitude-ft") or 0;
my_alt =  int(my_alt * 0.01);
my_alt *= 100;
setprop("/autopilot/afcs/settings/sel-target-altitude-ft", my_alt);
}

if  ((ap1 > 0) or (ap2 > 0))  {
var alt = getprop("/autopilot/afcs/settings/sel-target-altitude-ft") or 0;
alt= int(alt * 0.01);
alt *= 100;
setprop("/autopilot/afcs/settings/sel-target-altitude-ft", alt);
}

##


##
#AFCS Fly through when any Upper mode is engaged. With Autotrim enabled at low speed, without only at high speed  >40ktn#
##
var rollinput = getprop("/controls/flight/aileron") or 0;
var pitchinput = getprop("/controls/flight/elevator") or 0;
var FTR = getprop("/controls/flight/force_trim_release") or 0;
var atrimc = getprop("/autopilot/afcs/control/atrim") or 0;
var speed = getprop ("/instrumentation/airspeed-indicator/indicated-speed-kt") or 0; 
var atrim = getprop("/autopilot/afcs/internal/atrim") or 0;

if (atrimc > 0)  {
setprop("/autopilot/afcs/internal/atrim", 1);
}else{
setprop("/autopilot/afcs/internal/atrim", 0);
}


#kprrc = kp roll rate comparator

var kpRRC = 1;
var kpHHHold = 1;
var kpIASH = -1;
var kpCL = -0.0125;
var kpVSTRC = 1; 
var kpFPATRC = 12; 
var kpCRHTTCR = 1; 
var kpALTHTCR = 1; 
var kpALTATCR = 0.25; 


if   ( ((atrim >0) and (speed < 40)) and ((rollinput < -0.02) or (rollinput > 0.02)) and (FTR <1))  {
setprop("/autopilot/afcs/internal/flythrough-roll", 1 );
}elsif   ((speed > 40) and  ((rollinput < -0.02) or (rollinput > 0.02))and (FTR <1)) {
setprop("/autopilot/afcs/internal/flythrough-roll", 1 );
}else{
setprop("/autopilot/afcs/internal/flythrough-roll", 0 );
}

if   ( ((atrim >0) and (speed < 40)) and ((pitchinput < -0.02) or (pitchinput > 0.02)) and (FTR <1))  {
setprop("/autopilot/afcs/internal/flythrough-pitch", 1 );
}elsif   ((speed > 40) and  ((pitchinput < -0.02) or (pitchinput > 0.02))and (FTR <1)) {
setprop("/autopilot/afcs/internal/flythrough-pitch", 1 );
}else{
setprop("/autopilot/afcs/internal/flythrough-pitch", 0 );
}


#var centerFlightControls = func {
   # setprop("/controls/flight/elevator", 0);
   # setprop("/controls/flight/aileron", 0);
#}


#if   ((rollinput > -0.05) or (rollinput < 0.05) or  (FTR < 1) )  {

#interpolate("/autopilot/afcs/internal/kpRRC", kpRRC, 4 );
#interpolate("/autopilot/afcs/internal/kpHHHold", kpHHHold, 4 );
#}

#if   ((pitchinput > -0.05) or (pitchinput < 0.05) or  (FTR < 1) )  {

#interpolate("/autopilot/afcs/internal/kpIASH", kpIASH, 4 );
#interpolate("/autopilot/afcs/internal/kpCL", kpCL, 4 );

#interpolate("/autopilot/afcs/internal/kpVSTRC", kpVSTRC, 4 );
#interpolate("/autopilot/afcs/internal/kpFPATRC", kpFPATRC, 4 );
#interpolate("/autopilot/afcs/internal/kpCRHTTCR", kpCRHTTCR, 4 );
#interpolate("/autopilot/afcs/internal/kpALTHTCR", kpALTHTCR, 4 );
#interpolate("/autopilot/afcs/internal/kpALTATCR", kpALTATCR,  4 );
#}




##

if (headmode == 0){
var kpATTroll = 0.033 ;
var kpATTrollTi = 10 ;
setprop("/autopilot/afcs/internal/kpATTroll", kpATTroll );
setprop("/autopilot/afcs/internal/kpATTrollTi", kpATTrollTi );
}else{
setprop("/autopilot/afcs/internal/kpATTroll", 0.025 );
setprop("/autopilot/afcs/internal/kpATTrollTi", 10 );
}

if (speedmode == 0){
var kpATTpitch = -0.033; 
var kpATTpitchTi = 10; 
setprop("/autopilot/afcs/internal/kpATTpitch", kpATTpitch );
setprop("/autopilot/afcs/internal/kpATTpitchTi", kpATTpitchTi );
}else{
setprop("/autopilot/afcs/internal/kpATTpitch", -0.025 );
setprop("/autopilot/afcs/internal/kpATTpitchTi", 10 );
}

if (ias < 30){
			var kpHHHold = 1;
			interpolate("/autopilot/afcs/internal/kpHHHold", kpHHHold, 1 );
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
			interpolate("/autopilot/afcs/internal/kpHHHold2", kpHHHold2, 1);
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

if  ((ap1 > 0) or (ap2 > 0)) {
	   var FPangle = math.atan2(VSft, TASft) * R2D;
		setprop("autopilot/afcs/internal/fpa", (FPangle));
	}

settimer(afcs_action, 0.01);
}
afcs_action();
  

