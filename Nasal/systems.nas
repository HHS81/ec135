### some systems like hydraulics and engineoil, maingearboxoil etc...####


###oil pressure###
var oilpressure =  func {
#create oilpressure#


#fuelpump = props.globals.getNode("controls/engines/engine/fuel-pump", 1);
oilpres_low = props.globals.getNode("/engines/engine/oil-pressure-low", 1);
oilpres_norm = props.globals.getNode("/engines/engine/oil-pressure-norm", 1);
oilpres_bar = props.globals.getNode("/engines/engine/oil-pressure-bar", 1);

var rpm = props.globals.getNode("/engines/engine/rpm").getValue() or 0;
#var oilpres_psi = props.globals.getNode("/engines/engine/oil-pressure-psi").getValue() or 0;



oilpres_low.setDoubleValue((15-22000/rpm)*0.0689);

oilpres_norm.setDoubleValue((60-22000/rpm)*0.0689);


settimer(oilpressure, 0);
}
oilpressure();

##############

var oilpressurebar = func{

oilpres_bar = props.globals.getNode("/engines/engine/oil-pressure-bar", 1);

var rpm = props.globals.getNode("/engines/engine/rpm").getValue() or 0;
var oilpres_low = props.globals.getNode("/engines/engine/oil-pressure-low").getValue() or 0;
var oilpres_norm = props.globals.getNode("/engines/engine/oil-pressure-norm").getValue() or 0;

if ((rpm > 0) and (rpm < 23000)){        
            interpolate ("/engines/engine/oil-pressure-bar", oilpres_low, 1.5);
	    
}elsif (rpm > 23000) {        
            interpolate ("/engines/engine/oil-pressure-bar", oilpres_norm, 2);
      }
      
settimer(oilpressurebar, 0.1);
}
oilpressurebar();

##################
#var oiltemp = func{
#var OAT = props.globals.getNode("/environment/temperature-degc").getValue() or 0;
#var oilpres_bar = props.globals.getNode("/engines/engine/oil-pressure-bar-filter").getValue() or 0;
#var rpm = props.globals.getNode("/engines/engine/rpm").getValue() or 0;
#ot = props.globals.getNode("/engines/engine/oil-temperature-degc", 1);

#if (oilpres_bar >1){
#ot.setDoubleValue(((25-22000/rpm)*oilpres_bar)+OAT);
#}
#else{
#ot.setDoubleValue(OAT);
#}

#settimer( oiltemp, 0);
#}
#oiltemp();

#########################################
###main gear box oil pressure###
var mgbp =  func {
#create oilpressure#



mgb_oilpres_low = props.globals.getNode("/rotors/gear/mgb-oil-pressure-low", 1);
mgb_oilpres_norm = props.globals.getNode("/rotors/gear/mgb-oil-pressure-norm", 1);
mgb_oilpres_bar = props.globals.getNode("/rotors/gear/mgb-oil-pressure-bar", 1);

var rpm = props.globals.getNode("/rotors/main/rpm").getValue() or 0;
#var oilpres_psi = props.globals.getNode("/engines/engine/oil-pressure-psi").getValue() or 0;



mgb_oilpres_low.setDoubleValue((15-230/rpm)*0.0689);

mgb_oilpres_norm.setDoubleValue((60-230/rpm)*0.0689);


settimer(mgbp, 0);
}
mgbp();

##############

var mgbp_bar = func{

mgb_oilpres_bar = props.globals.getNode("/rotors/gear/mgb-oil-pressure-bar", 1);

var rpm = props.globals.getNode("/rotors/main/rpm").getValue() or 0;
mgb_oilpres_low = props.globals.getNode("/rotors/gear/mgb-oil-pressure-low").getValue() or 0;
mgb_oilpres_norm = props.globals.getNode("/rotors/gear/mgb-oil-pressure-norm").getValue() or 0;

if ((rpm > 0) and (rpm < 280)){        
            interpolate ("/rotors/gear/mgb-oil-pressure-bar",mgb_oilpres_low, 1.5);
	    
}elsif (rpm > 280) {        
            interpolate ("/rotors/gear/mgb-oil-pressure-bar",mgb_oilpres_norm, 2);
      }
      
settimer(mgbp_bar, 0.1);
}
mgbp_bar();








