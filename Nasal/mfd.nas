# mfd.nas to drive gauges of the EICAS MFD #

### changed by litzi:
### create engine torque ###

# Rational for engine torque for the moment, as full engine torque calculation
# may be kind of complex:
# The engine shafts are connected to the rotor via a fixed gear ratio 
# and with a free-wheeling mechanism.
# As long as both engine n2-rpm follow rotor rpm with fixed ratio (assuming 1:84) the 
# rotor torque is distributed between the engines according to the engines
# power settings.
# If enigne rpm falls behind rotor rpm (e.g. while in autorotation),
# the engine shaft gets disconnected from the gearbox and engine torque drops to zero.

# Turbomeca Arriel 1E2
# --------------------
# MCP                           ... 516 kW
# max. shaft torque             ... 986 Nm
# power shaft speed             ... 6000 rpm
# n1 100%.                      ... 51955 rpm
# n2 100%.                      ... 41586 rpm
# pwr shaft to n2 ratio.        ... 6.931
# ref: EASA E.073 TCDS Arriel 1 (Issue 3)

# PW 206 B3
# --------------------
# MCP                           ... 547 kW
# max. shaft torque             ... 851 Nm
# power shaft speed             ... 6134 rpm
# n1 100%.                      ... 57900 rpm
# n2 100%.                      ... 41282 rpm
# pwr shaft to n2 ratio.        ... 6.73
# ref: EASA TCDS PW206

var pi = 3.14159;
var PWR2TRQ = 60 / 2 / pi * 6.73;
var PWR2TRQPCT = PWR2TRQ / 851 * 100;

var max = func(a, b) a > b ? a : b;
var min = func(a, b) a < b ? a : b;

#set caution ranges for enigines oil temp and press gauges
setprop("/engines/oilt-caution-lo-degc",30);
setprop("/engines/oilt-caution-hi-degc",120);
setprop("/engines/oilp-caution-lo-bar",1.5);
setprop("/engines/oilp-caution-hi-bar",8);
 

var engtorque = func {
  var p = [0, 0];
  var rpm = [0, 0];
  var trq = [0, 0];
  var ratioN2 = 84;
  
  var pwr_total = props.globals.getValue("/rotors/gear/total-torque") or 0;
  p[0] = props.globals.getValue("/controls/engines/engine[0]/power") or 0;
  rpm[0] = props.globals.getValue("/engines/engine[0]/n2-rpm") or 0;
  p[1] = props.globals.getValue("/controls/engines/engine[1]/power") or 0;
  rpm[1] = props.globals.getValue("/engines/engine[1]/n2-rpm") or 0;
  pbal = props.globals.getValue("/controls/engines/power-balance") or 0;
  var rpmR = props.globals.getValue("/rotors/main/rpm") or 0;
  
  if (rpmR > 0) {
    # engine slower than rotor or inoperable?
    var balance =  (p[0] * (rpm[0]/rpmR > ratioN2 ? 1. : 0.) + p[1] * (rpm[1]/rpmR > ratioN2 ? 1. : 0.));
    if (balance > 0) {
      if (rpm[0]/rpmR > ratioN2) trq[0] = max(0,p[0]-pbal) /  balance ;
      if (rpm[1]/rpmR > ratioN2) trq[1] = max(0,p[1]+pbal) /  balance ;        
    } else {
      trq[0] = 0;
      trq[1] = 0;
    }
    interpolate("/engines/engine[0]/torque-pct", (rpm[0] > 10000 ? trq[0] * pwr_total / rpm[0] * PWR2TRQPCT : 0.) , 1);    
    interpolate("/engines/engine[1]/torque-pct", (rpm[1] > 10000 ? trq[1] * pwr_total / rpm[1] * PWR2TRQPCT : 0.) , 1);    
  }
  settimer(engtorque , 0.1);
}
#initialize torque update
engtorque();

###create fuelflow###

var fuelflow =  func(n){
  var power = props.globals.getValue("/controls/engines/engine[" ~ n ~ "]/power", 0);
  var rpm   = props.globals.getValue("/engines/engine[" ~ n ~ "]/n1-rpm") or 0;
  
  #by litzi: expose fuelflow in pound per hour to property tree
  if ( rpm > 0 ) interpolate ("/engines/engine[" ~ n ~ "]/fuel-flow_pph", power * 75. * 1./0.453592 , 1);
  
  settimer(func { fuelflow(n) }, 1);
}

fuelflow(0);
fuelflow(1);

### code copied from EC130.nas, original author Melchior Franz ###

###create oil pressure###

var oilpressure =  func(n){

  oilpres_low = props.globals.getNode("/engines/engine[" ~ n ~ "]/oil-pressure-low", 1);
  oilpres_norm = props.globals.getNode("/engines/engine[" ~ n ~ "]/oil-pressure-norm", 1);
  oilpres_bar = props.globals.getNode("/engines/engine[" ~ n ~ "]/oil-pressure-bar", 1);

  var rpm = props.globals.getValue("/engines/engine[" ~ n ~ "]/n2-rpm") or 0;

  if ( rpm > 0 ) oilpres_low.setDoubleValue((15-22000/rpm)*0.0689);
  if ( rpm > 0 ) oilpres_norm.setDoubleValue((60-22000/rpm)*0.0689);

  settimer(func { oilpressure(n) }, 0);
}

oilpressure(0);
oilpressure(1);

##############

var oilpressurebar = func(n){

  oilpres_bar = props.globals.getNode("/engines/engine[" ~ n ~ "]/oil-pressure-bar", 1);

  var rpm = props.globals.getValue("/engines/engine[" ~ n ~ "]/n2-rpm") or 0;
  var oilpres_low = props.globals.getValue("/engines/engine[" ~ n ~ "]/oil-pressure-low") or 0;
  var oilpres_norm = props.globals.getValue("/engines/engine[" ~ n ~ "]/oil-pressure-norm") or 0;

  # by litzi clamp oilpressure >= 0
  
  if ((rpm > 0) and (rpm < 23000)){
    interpolate ("/engines/engine[" ~ n ~ "]/oil-pressure-bar", max(oilpres_low, 0) , 1.5);
  }elsif (rpm > 23000) {
    interpolate ("/engines/engine[" ~ n ~ "]/oil-pressure-bar", max(oilpres_norm, 0) , 2);
  }

  settimer(func { oilpressurebar(n) }, 0.1);
}

oilpressurebar(0);
oilpressurebar(1);

##################

var oiltemp = func(n){

  var OAT = props.globals.getValue("/environment/temperature-degc") or 0;
  var oilpres_bar = props.globals.getValue("/engines/engine[" ~ n ~ "]/oil-pressure-bar") or 0;
  var rpm = props.globals.getValue("/engines/engine[" ~ n ~ "]/n2-rpm") or 0;
  ot = props.globals.getNode("/engines/engine[" ~ n ~ "]/oil-temperature-degc", 1);

  
  if (oilpres_bar >1){
    interpolate ("/engines/engine[" ~ n ~ "]/oil-temperature-degc", ((25-22000/rpm)*oilpres_bar)+OAT , 20);
  } else {
    interpolate ("/engines/engine[" ~ n ~ "]/oil-temperature-degc", OAT , 20);
  }

  settimer( func { oiltemp(n) }, 0);
}

oiltemp(0);
oiltemp(1);

#########################################

###main gear box oil pressure###
var mgbp =  func {

  #create oilpressure#
  mgb_oilpres_low = props.globals.getNode("/rotors/gear/mgb-oil-pressure-low", 1);
  mgb_oilpres_norm = props.globals.getNode("/rotors/gear/mgb-oil-pressure-norm", 1);
  mgb_oilpres_bar = props.globals.getNode("/rotors/gear/mgb-oil-pressure-bar", 1);

  var rpm = props.globals.getValue("/rotors/main/rpm") or 0;

  if ( rpm > 0 ) mgb_oilpres_low.setDoubleValue((15-230/rpm)*0.0689);
  if ( rpm > 0 ) mgb_oilpres_norm.setDoubleValue((60-230/rpm)*0.0689);

  settimer(mgbp, 0);
}

mgbp();

##############

var mgbp_bar = func{

  mgb_oilpres_bar = props.globals.getNode("/rotors/gear/mgb-oil-pressure-bar", 1);

  var rpm = props.globals.getValue("/rotors/main/rpm") or 0;
  mgb_oilpres_low = props.globals.getValue("/rotors/gear/mgb-oil-pressure-low") or 0;
  mgb_oilpres_norm = props.globals.getValue("/rotors/gear/mgb-oil-pressure-norm") or 0;

  if ((rpm > 0) and (rpm < 280)){
    interpolate ("/rotors/gear/mgb-oil-pressure-bar",max(mgb_oilpres_low,0), 1.5);
  }elsif (rpm > 280) {
    interpolate ("/rotors/gear/mgb-oil-pressure-bar",max(mgb_oilpres_norm,0), 2);
  }

  settimer(mgbp_bar, 0.1);
}

mgbp_bar();


#######VEMD######

# adopted from ec130 VEMD.nas 

####FLI = FirstLimitIndicator####
###Calculation into "FLI"###

var fliconvert= func {

var NG_eng0 = props.globals.getValue("/engines/engine/n1-pct") or 0;
var T4_eng0 = props.globals.getValue("/engines/engine/tot-degc") or 0;
var NG_eng1 = props.globals.getValue("/engines/engine[1]/n1-pct") or 0;
var T4_eng1 = props.globals.getValue("/engines/engine[1]/tot-degc") or 0;
var TRQ = props.globals.getValue("/sim/model/ec145/torque-pct") or 0;

var fliNG = min(NG_eng0, NG_eng1)/10;
var fliT4 = max(T4_eng0, T4_eng1)/100;
var fliTRQ = TRQ/7.5;

setprop ("instrumentation/VEMD/FLI/fliTRQ", fliTRQ);
setprop ("instrumentation/VEMD/FLI/fliT4", fliT4);
setprop ("instrumentation/VEMD/FLI/fliNG", fliNG);

settimer(fliconvert, 0.1);
}
setlistener("sim/signals/fdm-initialized", fliconvert);

###Interpolation###

var compare_roc = func {
    var fliNG = props.globals.getValue("instrumentation/VEMD/FLI/fliNG") or 0;
    var fliT4 = props.globals.getValue("instrumentation/VEMD/FLI/fliT4") or 0;
    var fliTRQ = props.globals.getValue("instrumentation/VEMD/FLI/fliTRQ") or 0;
    
    var delta_NG = props.globals.getValue("/instrumentation/VEMD/delta-n1-filter") or 0;
    var delta_TRQ = props.globals.getValue("/instrumentation/VEMD/delta-trq-filter") or 0;
    var delta_T4 = props.globals.getValue("/instrumentation/VEMD/delta-t4-filter") or 0;

   if (delta_NG > delta_TRQ){
        if (delta_NG > delta_T4){
            interpolate ("instrumentation/VEMD/FLI/FLI", fliNG, 2);
        } else {
            interpolate ("instrumentation/VEMD/FLI/FLI", fliT4, 2);
        }
   }else{
        if (delta_TRQ > delta_T4) {
            interpolate ("instrumentation/VEMD/FLI/FLI", fliTRQ, 2);
        }else{
            interpolate ("instrumentation/VEMD/FLI/FLI", fliT4, 2)
        }
	}

    settimer(compare_roc, 0.1);
}
setlistener("sim/signals/fdm-initialized", compare_roc);

#######
####different phases####
#initial phase- initial test phase#
#don't ask me- but it works as it should#

var initialphase = func{
tested = props.globals.getNode("instrumentation/VEMD/Phase/tested", 1);
var volts = props.globals.getNode("/systems/electrical/volts").getValue() or 0;

tested.setValue(0);

if (volts >22){
  tested.setValue(1);
  settimer(initialphase, 0.1);
}else{
  tested.setValue(0);
  settimer(initialphase, 4);
}
}
initialphase();

var flightphase = func{
tested = props.globals.getValue("instrumentation/VEMD/Phase/tested") or 0;
var pwr = props.globals.getValue("/systems/electrical/volts") or 0;
var n1 = props.globals.getValue("/engines/engine/n1-pct") or 0;
var rpm = props.globals.getValue("/rotors/main/rpm") or 0;
flphase = props.globals.getNode("instrumentation/VEMD/Phase/flight", 1);
sdphase = props.globals.getNode("instrumentation/VEMD/Phase/shutdown", 1);
var SEL = props.globals.getValue("/controls/engines/engine/startselector") or 0;
var delta_Nminus = props.globals.getValue("/instrumentation/VEMD/delta-n1") or 0;

if ((n1 >60) and (tested >0)){
  flphase.setValue(1);
} else {
  flphase.setValue(0);
}

if ((SEL < 1) and (delta_Nminus < 0) and (rpm <70) and (tested >0 )){
  sdphase.setValue(1);
} else {
  sdphase.setValue(0);
}


settimer(flightphase, 0.1);
}
flightphase();

# adopted from ec130 roc.nas 

var get_delta=func (current,previous) {return (current-previous);} 
var state = {new:func {return{parents:[state]};},n1_pct:0,trq_pct:0,t4_pct:0,timestamp:0,};

var update_state = func {
      var s = state.new();
      s.n1_pct=props.globals.getValue("/engines/engine/n1-pct") or 0;
      s.trq_pct=props.globals.getValue("/sim/model/ec130/torque-pct") or 0;
      s.t4_pct=props.globals.getValue("/engines/engine/tot-degc") or 0;
    
    s.timestamp=systime();
    return s;
}

var tvario = {   
  new: func {return {parents:[tvario]};},
  state:{previous:,current:},
  init: func {state.previous=state.new(); state.current=state.new();}, 
  update:func {

    state.current = update_state();   
  
    var delta_t = get_delta(state.current.timestamp, state.previous.timestamp);
  
    var deltan1 = get_delta(state.current.n1_pct,state.previous.n1_pct) / delta_t;
    var deltatrq = get_delta(state.current.trq_pct,state.previous.trq_pct) / delta_t;
    var deltat4 = get_delta(state.current.t4_pct,state.previous.t4_pct) / delta_t;
    
    setprop("/instrumentation/VEMD/delta-n1",deltan1);
    setprop("/instrumentation/VEMD/delta-trq",deltatrq);
    setprop("/instrumentation/VEMD/delta-t4",deltat4);

    state.previous = state.current; # save current state for next call
    settimer(func me.update(), 1/20); # update rate
  }
};

var tv = tvario.new();
tv.init();
tv.update();
