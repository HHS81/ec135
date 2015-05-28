##external stores and weights##

var weights = func {

float_deflated_right = props.globals.getNode("/sim/model/ec135/external/float_deflated_right/weight-lb", 1);
float_deflated_left = props.globals.getNode("/sim/model/ec135/external/float_deflated_left/weight-lb", 1);
float_inflated_right = props.globals.getNode("/sim/model/ec135/external/float_inflated_right/weight-lb", 1);
float_inflated_left = props.globals.getNode("/sim/model/ec135/external/float_inflated_left/weight-lb", 1);
HEMS = props.globals.getNode("/sim/model/ec135/external/HEMS/weight-lb", 1);
VIP = props.globals.getNode("/sim/model/ec135/external/VIP/weight-lb", 1);
Utility = props.globals.getNode("/sim/model/ec135/external/Utility/weight-lb", 1);
BigRadom = props.globals.getNode("/sim/model/ec135/external/BigRadom/weight-lb", 1);
smallradom = props.globals.getNode("/sim/model/ec135/external/smallradom/weight-lb", 1);
searchlight_front = props.globals.getNode("/sim/model/ec135/external/searchlight_front/weight-lb", 1);
searchlight_left = props.globals.getNode("/sim/model/ec135/external/searchlight_left/weight-lb", 1);
FLIR = props.globals.getNode("/sim/model/ec135/external/FLIR/weight-lb", 1);
mirror = props.globals.getNode("/sim/model/ec135/external/mirror/weight-lb", 1);
wirecutter_up = props.globals.getNode("/sim/model/ec135/external/wirecutter_up/weight-lb", 1);
wirecutter_down = props.globals.getNode("/sim/model/ec135/external/wirecutter_down/weight-lb", 1);
sandfilter = props.globals.getNode("/sim/model/ec135/external/sandfilter/weight-lb", 1);
IBF = props.globals.getNode("/sim/model/ec135/external/IBF/weight-lb", 1);
winch = props.globals.getNode("/sim/model/ec135/external/winch/weight-lb", 1);
SLLightL = props.globals.getNode("/sim/model/ec135/external/SLLightL/weight-lb", 1);
SLLightR = props.globals.getNode("/sim/model/ec135/external/SLLightR/weight-lb", 1);
loudspeaker = props.globals.getNode("/sim/model/ec135/external/loudspeaker/weight-lb", 1);
hellas = props.globals.getNode("/sim/model/ec135/external/hellas/weight-lb", 1);
snowboard_lowskid = props.globals.getNode("/sim/model/ec135/external/snowboard_lowskid/weight-lb", 1);
wirecutter_skid = props.globals.getNode("/sim/model/ec135/external/wirecutter_skid/weight-lb", 1);
longskid_floats = props.globals.getNode("/sim/model/ec135/external/longskid_floats/weight-lb", 1);
midskid = props.globals.getNode("/sim/model/ec135/external/midskid/weight-lb", 1);
snowboard_midskid = props.globals.getNode("/sim/model/ec135/external/snowboard_midskid/weight-lb", 1);
wirecutter_midskid = props.globals.getNode("/sim/model/ec135/external/wirecutter_midskid/weight-lb", 1);
highskid = props.globals.getNode("/sim/model/ec135/external/highskid/weight-lb", 1);
snowboard_highskid = props.globals.getNode("/sim/model/ec135/external/snowboard_highskid/weight-lb", 1);
wirecutter_highskid = props.globals.getNode("/sim/model/ec135/external/wirecutter_highskid/weight-lb", 1);
multifunctioncarrier = props.globals.getNode("/sim/model/ec135/external/multifunctioncarrier/weight-lb", 1);
DoubleCargoHook = props.globals.getNode("/sim/model/ec135/external/DoubleCargoHook/weight-lb", 1);
buckle = props.globals.getNode("/sim/model/ec135/external/buckle/weight-lb", 1);


if (getprop("/sim/model/ec135/emergfloats")=="true"){
float_deflated_right.setValue(79.8);
float_deflated_left.setValue(79.8);
}else{
float_deflated_right.setValue(0);
float_deflated_left.setValue(0);
}

#now the inflated floats- they keep their weight of course as with inflation now additional weight is added, but they influences now the aerodynamic. So we set weight to zero, but YASim will increase drag#
if(getprop("/controls/gear/floats-inflat")=="true"){
float_inflated_right.setValue(0);
float_inflated_left.setValue(0);
}else{
float_inflated_right.setValue(0);
float_inflated_left.setValue(0);
}

if(getprop("/controls/gear/floats-inflat")=="true"){
float_inflated_right.setValue(0);
float_inflated_left.setValue(0);
}else{
float_inflated_right.setValue(0);
float_inflated_left.setValue(0);
}

if (getprop("/sim/model/ec135/HEMS")=="true"){
HEMS.setValue(468);
}else{
HEMS.setValue(0);
}

if (getprop("/sim/model/ec135/VIP")=="true"){
VIP.setValue(263);
}else{
VIP.setValue(0);
}

if (getprop("/sim/model/ec135/Utility")=="true"){
Utility.setValue(131);
}else{
Utility.setValue(0);
}

if (getprop("/sim/model/ec135/BigRadom")=="true"){
BigRadom.setValue(25);
}else{
BigRadom.setValue(0);
}

if (getprop("/sim/model/ec135/smallradom")=="true"){
smallradom.setValue(10);
}else{
smallradom.setValue(0);
}

if (getprop("/sim/model/ec135/searchlight_front")=="true"){
searchlight_front.setValue(28);
}else{
searchlight_front.setValue(0);
}

if (getprop("/sim/model/ec135/searchlight_left")=="true"){
searchlight_left.setValue(82.3);
}else{
searchlight_left.setValue(0);
}


if (getprop("/sim/model/ec135/FLIR")=="true"){
FLIR.setValue(40);
}else{
FLIR.setValue(0);
}

if (getprop("/sim/model/ec135/mirror")=="true"){
mirror.setValue(10.4);
}else{
mirror.setValue(0);
}

if (getprop("/sim/model/ec135/wirecutter_up")=="true"){
wirecutter_up.setValue(8.5);
}else{
wirecutter_up.setValue(0);
}

if (getprop("/sim/model/ec135/wirecutter_down")=="true"){
wirecutter_down.setValue(8.5);
}else{
wirecutter_down.setValue(0);
}

if (getprop("/sim/model/ec135/sandfilter")=="true"){
sandfilter.setValue(82.7);
}else{
sandfilter.setValue(0);
}

if (getprop("/sim/model/ec135/IBF")=="true"){
IBF.setValue(59.5);
}else{
IBF.setValue(0);
}

if (getprop("/sim/model/ec135/winch")=="true"){
winch.setValue(157.2);
}else{
winch.setValue(0);
}

if (getprop("/sim/model/ec135/SLLightL")=="true"){
SLLightL.setValue(6.8);
}else{
SLLightL.setValue(0);
}

if (getprop("/sim/model/ec135/SLLightR")=="true"){
SLLightR.setValue(6.8);
}else{
SLLightR.setValue(0);
}

if (getprop("/sim/model/ec135/loudspeaker")=="true"){
loudspeaker.setValue(24.7);
}else{
loudspeaker.setValue(0);
}

if (getprop("/sim/model/ec135/hellas")=="true"){
hellas.setValue(50.0);
}else{
hellas.setValue(0);
}

if (getprop("/sim/model/ec135/snowboard_lowskid")=="true"){
snowboard_lowskid.setValue(50.3);
}else{
snowboard_lowskid.setValue(0);
}

if (getprop("/sim/model/ec135/wirecutter_skid")=="true"){
wirecutter_skid.setValue(8.3);
}else{
wirecutter_skid.setValue(0);
}

if (getprop("/sim/model/ec135/longskid_floats")=="true"){
longskid_floats.setValue(18.3);
}else{
longskid_floats.setValue(0);
}

if (getprop("/sim/model/ec135/midskid")=="true"){
midskid.setValue(10.1);
}else{
midskid.setValue(0);
}

if (getprop("/sim/model/ec135/snowboard_midskid")=="true"){
snowboard_midskid.setValue(50.3);
}else{
snowboard_midskid.setValue(0);
}

if (getprop("/sim/model/ec135/wirecutter_midskid")=="true"){
wirecutter_midskid.setValue(8.3);
}else{
wirecutter_midskid.setValue(0);
}

if (getprop("/sim/model/ec135/highskid")=="true"){
highskid.setValue(57.3);
}else{
highskid.setValue(0);
}

if (getprop("/sim/model/ec135/snowboard_highskid")=="true"){
snowboard_highskid.setValue(50.3);
}else{
snowboard_highskid.setValue(0);
}

if (getprop("/sim/model/ec135/wirecutter_highskid")=="true"){
wirecutter_highskid.setValue(8.3);
}else{
wirecutter_highskid.setValue(0);
}

if (getprop("/sim/model/ec135/multifunctioncarrier")=="true"){
multifunctioncarrier.setValue(21.6);
}else{
multifunctioncarrier.setValue(0);
}

if (getprop("/sim/model/ec135/buckle")=="true"){
buckle.setValue(2.2);
}else{
buckle.setValue(0);
}

##to do: the missing weights ##




settimer(weights,0.1);
}
weights();