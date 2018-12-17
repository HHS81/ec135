#### H135 AFCS ####
#### by H. Schulz for  ####

var afcs_action = func{


var ap = getprop("/autopilot/afcs/engaged") or 0;

##
if (ap > 0)  {
var my_vs = getprop("/autopilot/internal/vert-speed-fpm") or 0;
my_vs =  int(my_vs * 0.01);
my_vs *= 100;
if(my_vs>4000)my_vs=4000;
if(my_vs<-8000)my_vs=-8000;
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
#if(my_vfps>42)my_vfps=42;
#if(my_vfps<-42)my_vfps=-42;
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
#if(my_ufps>42)my_ufps=42;
#if(my_ufps<0)my_ufps=0;
setprop("/autopilot/afcs/internal/uBody-fps",my_ufps);
}
if (ap > 0) {
var sups = getprop("/autopilot/afcs/internal/uBody-fps") or 0;
sups= int(sups * 10);
sups *= 0.1;
setprop("/autopilot/afcs/internal/uBody-fps",sups);
}

##



settimer(afcs_action, 0.01);
}
afcs_action();
  

