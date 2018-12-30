####  electrical system taken from the S76C, modified for Ec135 after POH  #### 
####    Syd Adams    ####

var epu = func{
var EP  = props.globals.getNode("/controls/electric/external-power").getValue() or 0;
if (EP >0){
setprop("/systems/electrical/external_volts", 29);
}else{
setprop("/systems/electrical/external_volts", 0);
}
settimer(epu, 0.1);
}
epu();

var ws = func{
var swt  = props.globals.getNode("/controls/special/wiper-switch").getValue() or 0;
var pwr  = props.globals.getNode("/systems/electrical/volts").getValue() or 0;

if (swt>0){
setprop("/systems/electrical/outputs/wiper", pwr);
}else{
setprop("/systems/electrical/outputs/wiper", 0);
}
settimer(ws, 0.1);
}
ws();





var count=0;
var ammeter_ave = 0.0;
var outPut = "systems/electrical/outputs/";
var BattVolts = props.globals.getNode("systems/electrical/batt-volts",1);
var Volts = props.globals.getNode("/systems/electrical/volts",1);
var Amps = props.globals.getNode("/systems/electrical/amps",1);
var EXT  = props.globals.getNode("/controls/electric/external-power",1); 
var Lbus = props.globals.initNode("/systems/electrical/left-bus",0,"DOUBLE");
var Rbus = props.globals.initNode("/systems/electrical/right-bus",0,"DOUBLE");
var XTie  = props.globals.initNode("/systems/electrical/xtie",0,"BOOL");
var lbus_volts = 0.0;
var rbus_volts = 0.0;

var lbus_input=[];
var lbus_output=[];
var lbus_load=[];

var rbus_input=[];
var rbus_output=[];
var rbus_load=[];

var switch_list=[];
var output_list=[];
var watt_list=[];


strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("/systems/electrical/outputs/strobe", [0.03, 1.20], strobe_switch);
beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("/systems/electrical/outputs/beacon", [0.5, 1.5], beacon_switch);


#var battery = Battery.new(switch-prop,volts,amps,amp_hours,charge_percent,charge_amps);
Battery = {
    new : func(swtch,vlt,amp,hr,chp,cha){
    m = { parents : [Battery] };
            m.switch = props.globals.getNode(swtch,1);
            m.switch.setBoolValue(0);
            m.ideal_volts = vlt;
            m.ideal_amps = amp;
            m.amp_hours = hr;
            m.charge_percent = chp; 
            m.charge_amps = cha;
    return m;
    },
    apply_load : func(load,dt) {
        if(me.switch.getValue()){
        var amphrs_used = load * dt / 3600.0;
        var percent_used = amphrs_used / me.amp_hours;
        me.charge_percent -= percent_used;
        if ( me.charge_percent < 0.0 ) {
            me.charge_percent = 0.0;
        } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
        }
        var output =me.amp_hours * me.charge_percent;
        return output;
        }else return 0;
    },

    get_output_volts : func {
        if(me.switch.getValue()){
            var x = 1.0 - me.charge_percent;
            var tmp = -(3.0 * x - 1.0);
            var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
            var output =me.ideal_volts * factor;
            return output;
        }else return 0;
    },

    get_output_amps : func {
        if(me.switch.getValue()){
            var x = 1.0 - me.charge_percent;
            var tmp = -(3.0 * x - 1.0);
            var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
            var output =me.ideal_amps * factor;
            return output;
        }else return 0;
    }
};

# var alternator = Alternator.new(num,switch,rpm_source,rpm_threshold,volts,amps);
Alternator = {
    new : func (num,switch,src,thr,vlt,amp){
        m = { parents : [Alternator] };
        m.switch =  props.globals.getNode(switch,1);
        m.switch.setBoolValue(0);
        m.meter =  props.globals.getNode("systems/electrical/gen-load["~num~"]",1);
        m.meter.setDoubleValue(0);
        m.gen_output =  props.globals.getNode("engines/engine["~num~"]/amp-v",1);
        m.gen_output.setDoubleValue(0);
        m.meter.setDoubleValue(0);
        m.rpm_source =  props.globals.getNode(src,1);
        m.rpm_threshold = thr;
        m.ideal_volts = vlt;
        m.ideal_amps = amp;
        return m;
    },

    apply_load : func(load) {
        var cur_volt=me.gen_output.getValue();
        var cur_amp=me.meter.getValue();
        if(cur_volt >1){
            var factor=1/cur_volt;
            gout = (load * factor);
            if(gout>1)gout=1;
        }else{
            gout=0;
        }
        if(cur_amp > gout)me.meter.setValue(cur_amp - 0.01);
        if(cur_amp < gout)me.meter.setValue(cur_amp + 0.01);
    },

    get_output_volts : func {
        var out = 0;
        if(me.switch.getBoolValue()){
            var factor = me.rpm_source.getValue() / me.rpm_threshold;
            if ( factor > 1.0 )factor = 1.0;
            var out = (me.ideal_volts * factor);
        }
        me.gen_output.setValue(out);
        return out;
    },

    get_output_amps : func {
        var ampout =0;
        if(me.switch.getBoolValue()){
            var factor = me.rpm_source.getValue() / me.rpm_threshold;
            if ( factor > 1.0 ) {
                factor = 1.0;
            }
            ampout = me.ideal_amps * factor;
        }
        return ampout;
    }
};

# var alternator = Alternator.new(num,switch,rpm_source,rpm_threshold,volts,amps);
var battery = Battery.new("/controls/electric/battery-switch",24,40,15,1.0,7.0);
var alternator1 = Alternator.new(0,"controls/electric/engine[0]/generator","/engines/engine[0]/n2-rpm",7000.0,30.0,200.0);
var alternator2 = Alternator.new(1,"controls/electric/engine[1]/generator","/engines/engine[1]/n2-rpm",7000.0,30.0,200.0);

#####################################
setlistener("/sim/signals/fdm-initialized", func {
    BattVolts.setDoubleValue(0);
    init_switches();
    settimer(update_electrical,5);
    print("Electrical System ... ok");

});

init_switches = func() {
    var tprop=props.globals.getNode("controls/electric/ammeter-switch",1);
    tprop.setBoolValue(1);
    tprop=props.globals.getNode("controls/lighting/instrument-lights",1);
    tprop.setBoolValue(0);

    setprop("controls/lighting/instrument-lights-norm",0.5);
   setprop("controls/lighting/stdby-instrument-lights-norm",0.5);

    append(switch_list,"controls/engines/engine[0]/fadec/fadec-switch");
    append(output_list,"fadec1");
    append(watt_list,16.0);
    
    append(switch_list,"controls/engines/engine[1]/fadec/fadec-switch");
    append(output_list,"fadec2");
    append(watt_list,16.0);


    append(switch_list,"controls/engines/engine/starter");
    append(output_list,"starter");
    append(watt_list,64.0);
    
    append(switch_list,"controls/engines/engine[1]/starter");
    append(output_list,"starter");
    append(watt_list,64.0);
        
    append(switch_list,"controls/anti-ice/pitot-heat");
    append(output_list,"pitot-heat");
    append(watt_list,0.5);
    
    append(switch_list,"controls/anti-ice/pitot-heat2");
    append(output_list,"pitot-heat2");
    append(watt_list,0.5);

    append(switch_list,"controls/lighting/landing-lights");
    append(output_list,"landing-light");
    append(watt_list,10.0);

    append(switch_list,"controls/lighting/instrument-lights");
    append(output_list,"instrument-lights");
    append(watt_list,10);
    
    append(switch_list,"controls/lighting/stdby-instrument-lights");
    append(output_list,"stdby-instrument-lights");
    append(watt_list,10);
    
       
    append(switch_list,"controls/lighting/dome-light");
    append(output_list,"dome-light");
    append(watt_list,10);

    append(switch_list,"controls/lighting/beacon");
    append(output_list,"beacon");
    append(watt_list,0.5);
    
    append(switch_list,"controls/lighting/strobe");
    append(output_list,"strobe");
    append(watt_list,0.5);


    append(switch_list,"controls/lighting/nav-lights");
    append(output_list,"nav-lights");
    append(watt_list,16);
    
    append(switch_list,"controls/switches/fuel/transfer-pump[0]");
    append(output_list,"transfer-pump-forward");
    append(watt_list,16);
    
    append(switch_list,"controls/switches/fuel/transfer-pump[1]");
    append(output_list,"transfer-pump-aft");
    append(watt_list,16);

    append(switch_list,"controls/fuel/tank[1]/prime-pump");
    append(output_list,"prime-pump1");
    append(watt_list,16);
    
    append(switch_list,"controls/fuel/tank[2]/prime-pump");
    append(output_list,"prime-pump2");
    append(watt_list,16);

    append(switch_list,"controls/electric/warningtest");
    append(output_list,"wlttest");
    append(watt_list,0.5);

    append(switch_list,"controls/electric/firetest");
    append(output_list,"firetest");
    append(watt_list,0.5);
    
    append(switch_list,"controls/electric/CWS");
    append(output_list,"CWS");
    append(watt_list,0.5);
    
    append(switch_list,"controls/electric/servo");
    append(output_list,"servo");
    append(watt_list,0.5);
       
    append(switch_list,"controls/electric/attitude");
    append(output_list,"attitude");
    append(watt_list,0.5);
    
    append(switch_list,"controls/electric/avionics-switch1");
    append(output_list,"avionics-switch");
    append(watt_list,0.2);
    
    append(switch_list,"controls/electric/avionics-switch2");
    append(output_list,"avionics-switch2");
    append(watt_list,0.2);
    
    append(switch_list,"controls/electric/avionics-switch1");
    append(output_list,"adf");
    append(watt_list,0.2);
    
    append(switch_list,"controls/electric/gyrocompass");
    append(output_list,"gyrocompass");
    append(watt_list,0.5);
    
    append(switch_list,"controls/electric/turn-coordinator");
    append(output_list,"turn-coordinator");
    append(watt_list,0.5);

    append(switch_list,"controls/electric/avionics-switch1");
    append(output_list,"dme");
    append(watt_list,0.2);

    append(switch_list,"controls/electric/avionics-switch1");
    append(output_list,"adf");
    append(watt_list,0.2);

    append(switch_list,"controls/electric/avionics-switch1");
    append(output_list,"adf");
    append(watt_list,0.2);

    append(switch_list,"controls/electric/avionics-switch1");
    append(output_list,"DG");
    append(watt_list,0.2);

    append(switch_list,"controls/electric/avionics-switch1");
    append(output_list,"transponder");
    append(watt_list,0.2);

    append(switch_list,"controls/electric/avionics-switch1");
    append(output_list,"turn-coordinator");
    append(watt_list,0.2);

    append(switch_list,"controls/electric/avionics-switch1");
    append(output_list,"comm");
    append(watt_list,0.2);

    append(switch_list,"controls/electric/avionics-switch1");
    append(output_list,"comm[1]");
    append(watt_list,10);

    append(switch_list,"controls/electric/avionics-switch1");
    append(output_list,"nav");
    append(watt_list,10);

    append(switch_list,"controls/electric/avionics-switch1");
    append(output_list,"nav[1]");
    append(watt_list,10);
    
    append(switch_list,"controls/electric/avionics-switch1");
    append(output_list,"afcs");
    append(watt_list,0.2);
    
    append(switch_list,"controls/electric/direct-battery");
    append(output_list,"transponder");
    append(watt_list,10);
    
    append(switch_list,"controls/electric/direct-battery");
    append(output_list,"NRgauge");
    append(watt_list,10);
    
    append(switch_list,"controls/electric/direct-battery");
    append(output_list,"instrument-lights2");
    append(watt_list,10);
    
    #append(switch_list,"controls/electric/direct-battery");
    #append(output_list,"dome-light");
    #append(watt_list,10);
    
    append(switch_list,"controls/electric/direct-battery");
    append(output_list,"emerg-float");
    append(watt_list,16);
    
    #append(switch_list,"controls/electric/wiper/switch");
    #append(output_list,"wiper");
    #append(watt_list,10);
    
#append(switch_list,"controls/electric/wiper/switch");
    #append(output_list,"wiper-right");
    #append(watt_list,10);


    
  

    for(var i=0; i<size(switch_list); i+=1) {
        var tmp = props.globals.getNode(switch_list[i],1);
        tmp.setBoolValue(0);
    }
setprop("controls/electric/master-switch",1);
}

#########

##################################
update_virtual_bus = func( dt ) {
    var PWR = getprop("systems/electrical/serviceable");
    var battery_volts = battery.get_output_volts();
    BattVolts.setValue(battery_volts);
     
    var external_volts = props.globals.getNode("/systems/electrical/external_volts").getValue() or 0; 
    
    var batepu_sw = props.globals.getNode("/controls/electric/battery-switch").getValue() or 0; 
    var EP  = props.globals.getNode("/controls/electric/external-power").getValue() or 0;
 
	var xtie=0;
	load = 0.0;
	bus_volts = 0.0;
	power_source = nil;
	lbus_volts = battery_volts;
	rbus_volts = battery_volts;
	bus_volts = battery_volts;
	power_source = "battery";


var alternator1_volts = alternator1.get_output_volts();
        if (alternator1_volts > lbus_volts) {
            lbus_volts = alternator1_volts;
            power_source = "alternator1";
        }
	if ((external_volts > lbus_volts) and (batepu_sw >0)){
            lbus_volts = external_volts;
            power_source = "external_volts";
        }
   var alternator2_volts = alternator2.get_output_volts();
        if (alternator2_volts > rbus_volts) {
            rbus_volts = alternator2_volts;
            power_source = "alternator2";
        }
	
	
	
	if ((external_volts > rbus_volts)and (batepu_sw >0)) {
            rbus_volts = external_volts;
            power_source = "external_volts";
        }


   	if ((external_volts > lbus_volts) and (batepu_sw >0)){
            lbus_volts = external_volts;
            power_source = "external_volts";
        }
	if (EP >0){
         BattVolts.setValue(0);
         }

	rbus_volts *=PWR;
	Rbus.setValue(rbus_volts);
	
	lbus_volts *=PWR;
        Lbus.setValue(lbus_volts);
	

    load += electrical_bus(rbus_volts + lbus_volts);
    
	count=1-count;
	if(rbus_volts > 5 and  lbus_volts>5) xtie=1;
	XTie.setValue(xtie);

    ammeter = 0.0;

    if ( power_source == "battery" ) {
        ammeter = -load;
        } else {
        ammeter = battery.charge_amps;
    }

    if ( power_source == "battery" ) {
        battery.apply_load( load, dt );
        } elsif ( bus_volts > battery_volts ) {
        battery.apply_load( -battery.charge_amps, dt );
        }

    ammeter_ave = 0.8 * ammeter_ave + 0.2 * ammeter;

   Amps.setValue(ammeter_ave);
   Volts.setValue(bus_volts);
    alternator1.apply_load(load);
    alternator2.apply_load(load);

return load;
}

################################

electrical_bus = func(bv) {
    var bus_volts = bv;
    var load = 0.0;
    var srvc = 0.0;


    for(var i=0; i<size(switch_list); i+=1) {
        var srvc = getprop(switch_list[i]);
        load = load + srvc * watt_list[i];
        setprop(outPut~output_list[i],bus_volts * srvc);
    }

    var DIMMER = bus_volts * getprop("controls/lighting/instrument-lights-norm");
    var INSTR_SWTCH = getprop("controls/lighting/instrument-lights");
    DIMMER=DIMMER*INSTR_SWTCH;
    
    var DIMMER2 = bus_volts * getprop("controls/lighting/stdby-instrument-lights-norm");
        var STBY_INSTR_SWTCH = getprop("controls/lighting/instrument-lights");
    DIMMER2=DIMMER2*STBY_INSTR_SWTCH;

    setprop(outPut~"instrument-lights",DIMMER);
    setprop(outPut~"instrument-lights-norm",DIMMER * 0.0344);
    
    if (getprop("/systems/electrical/outputs/instrument-lights-norm") >1.0){
    setprop("/systems/electrical/outputs/instrument-lights-norm", 1.0)};
    
    setprop(outPut~"stdby-instrument-lights",DIMMER2);
    setprop(outPut~"stdby-instrument-lights-norm",DIMMER2 * 0.0344);
    
    if (getprop("/systems/electrical/outputs/afcs") >22.0){
    setprop("/autopilot/afcs/engaged", 1)
    }else{
    setprop("/autopilot/afcs/engaged", 0)};
    
#replace casdisable.nas-> disable cas when engines running- otherwise we are overflooded with error messages in the console

var rpm = getprop("/rotors/main/rpm") or 0;

if ((bus_volts > 0.0) and (rpm > 50)) {
setprop("/controls/flight/fcs/switches/cas", 0);
}else {
setprop("/controls/flight/fcs/switches/cas", 1.0);
}
    

    return load;
}

######################


######################

update_electrical = func {
    var scnd = getprop("sim/time/delta-sec");
    update_virtual_bus( scnd );

settimer(update_electrical, 0);
}




