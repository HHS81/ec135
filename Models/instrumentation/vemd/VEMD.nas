#######VEMD######

####FLI = FirstLimitIndicator####
###Calculation into "FLI"###

var fliconvert= func {

var NG = props.globals.getNode("/engines/engine/n1-pct").getValue() or 0;
var T4 = props.globals.getNode("/engines/engine/tot-degc").getValue() or 0;
#var NG2 = props.globals.getNode("/engines/engine[1]/n1-pct").getValue() or 0;
#var T42 = props.globals.getNode("/engines/engine[1]/tot-degc").getValue() or 0;
var TRQ = props.globals.getNode("/sim/model/ec135/torque-pct").getValue() or 0;



var fliNG = NG/10;
var fliT4 = T4/100;
var fliTRQ = TRQ/7.5;

#var fliNG2 = NG2/10;
#var fliT42 = T42/100;


setprop ("instrumentation/VEMD/FLI/fliTRQ", fliTRQ);
setprop ("instrumentation/VEMD/FLI/fliT4", fliT4);
setprop ("instrumentation/VEMD/FLI/fliNG", fliNG);

#setprop ("instrumentation/VEMD/FLI2/fliTRQ", fliTRQ);
#setprop ("instrumentation/VEMD/FLI2/fliT42", fliT4);
#setprop ("instrumentation/VEMD/FLI2/fliNG2", fliNG);

settimer(fliconvert, 0.1);
}
setlistener("sim/signals/fdm-initialized", fliconvert);

###Interpolation###



var compare_roc = func {
    var fliNG = props.globals.getNode("instrumentation/VEMD/FLI/fliNG").getValue() or 0;
    var fliT4 = props.globals.getNode("instrumentation/VEMD/FLI/fliT4").getValue() or 0;
     var fliTRQ = props.globals.getNode("instrumentation/VEMD/FLI/fliTRQ").getValue() or 0;
     
    
    var delta_NG = props.globals.getNode("/instrumentation/VEMD/delta-n1-filter").getValue() or 0;
    var delta_TRQ = props.globals.getNode("/instrumentation/VEMD/delta-trq-filter").getValue() or 0;
    var delta_T4 = props.globals.getNode("/instrumentation/VEMD/delta-t4-filter").getValue() or 0;
 





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
tested = props.globals.getNode("instrumentation/VEMD/Phase/tested").getValue() or 0;
var pwr = props.globals.getNode("/systems/electrical/volts").getValue() or 0;
var n1 = props.globals.getNode("/engines/engine/n1-pct").getValue() or 0;
var rpm = props.globals.getNode("/rotors/main/rpm").getValue() or 0;
flphase = props.globals.getNode("instrumentation/VEMD/Phase/flight", 1);
sdphase = props.globals.getNode("instrumentation/VEMD/Phase/shutdown", 1);
var SEL = props.globals.getNode("controls/engines/engine[0]/fadec/engine-state").getValue() or 0;
var delta_Nminus = props.globals.getNode("/instrumentation/VEMD/delta-n1").getValue() or 0;


if ((n1 >60) and (tested >0)){
flphase.setValue(1);
}
else{
flphase.setValue(0);
}


if ((SEL < 1) and (delta_Nminus < 0) and (rpm <70) and (tested >0 )){
sdphase.setValue(1);
}else{
sdphase.setValue(0);
}


settimer(flightphase, 0.1);
}
flightphase();



