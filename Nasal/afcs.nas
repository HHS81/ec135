#### H135 AFCS ####
#### by H. Schulz for  ####

var afcs_action = func{


var ap = getprop("/autopilot/afcs/engaged") or 0;
var ias = getprop("/instrumentation/airspeed-indicator/indicated-speed-kt") or 0;

##
if (ap > 0)  {
var my_vs = getprop("/autopilot/internal/vert-speed-fpm") or 0;
my_vs =  int(my_vs * 0.01);
my_vs *= 100;
if(my_vs>2200)my_vs=2200;
if(my_vs<-2200)my_vs=-2200;
setprop("autopilot/afcs/settings/fpm",my_vs);
}
if (ap > 0) {
var vsw = getprop("autopilot/afcs/settings/fpm") or 0;
vsw = int(vsw * 0.01);
vsw *= 100;
setprop("autopilot/afcs/settings/fpm",vsw);
}

##

if (ap > 0)  {
var my_vfps = getprop("/autopilot/afcs/internal/vBody-fps") or 0;
my_vfps =  int(my_vfps * 10);
my_vfps *= 0.1;

setprop("/autopilot/afcs/internal/vBody-fps",my_vfps);
}
if (ap > 0) {
var svps = getprop("/autopilot/afcs/internal/vBody-fps") or 0;
svps = int(svps * 10);
svps *= 0.1;
setprop("/autopilot/afcs/internal/vBody-fps",svps);
}

##

if (ap > 0)  {
var my_ufps = getprop("/autopilot/afcs/internal/uBody-fps") or 0;
my_ufps =  int(my_ufps * 10);
my_ufps *= 0.1;

setprop("/autopilot/afcs/internal/uBody-fps",my_ufps);
}
if (ap > 0) {
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
		var VSft= ((VS * FT2M));  

       if (ap > 0) {
	   var FPangle = math.atan2(VSft, TASft) * R2D;
            setprop("autopilot/afcs/internal/fpa", (FPangle * -1));
        }

settimer(afcs_action, 0.01);
}
afcs_action();
  

