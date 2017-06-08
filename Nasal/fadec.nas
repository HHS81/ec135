###EC135 FADEC###
#simple hack- needs some work to look more professionell#


#sling load test#

#var tforce = func{


#loadforce = props.globals.getNode("/sim/ai/ballistic/force[2]/force-lb", 1);
#var towforce = getprop("/sim/hitches/aerotow/force");
#var towforce2 = getprop("/sim/hitches/aerotow/tow/end-force-z");
#test2 = props.globals.getNode("/sim/ai/ballistic/test", 1);
#var hitch = getprop("/sim/hitches/aerotow/open");

#if (getprop("/sim/hitches/aerotow/open") > 0){

#loadforce.setValue(0);
#test2.setValue(1);
#}
#else{
#loadforce.setValue((towforce * 0.225));
#test2.setValue((towforce2 * 0.225));
#}


#settimer(tforce, 0.1);
#}
#tforce();

###State of fuellines- if filled up engine can run- if not engine cuts off###
#simpel hack- known issue: boost-pump runs even without power#


var primepumps = func {

	flines_filled1 = props.globals.getNode("/controls/fuel/tank/fuellines_filled", 1);
	flines_filled2 = props.globals.getNode("/controls/fuel/tank[1]/fuellines_filled", 1);
	var primepump1 = props.globals.getNode("/systems/electrical/outputs/prime-pump1").getValue() or 0;
	var primepump2 = props.globals.getNode("/systems/electrical/outputs/prime-pump2").getValue() or 0;
	var CUTOFF1 = props.globals.getNode("/controls/engines/engine/cutoff").getValue() or 0;
	var CUTOFF2 = props.globals.getNode("/controls/engines/engine[1]/cutoff").getValue() or 0;
	var n11 = props.globals.getNode("/engines/engine[0]/n1-pct").getValue() or 0;
	var n12 = props.globals.getNode("/engines/engine[1]/n1-pct").getValue() or 0;
	var VOLTS = props.globals.getNode("/systems/electrical/volts").getValue() or 0;
	var bp_pwr = getprop("/systems/electrical/outputs/boost-pump");

	if (n11 < 60) {
		if (primepump1 > 24) {
			interpolate ("/controls/fuel/tank/fuellines_filled",1, 5);
		} else {
			interpolate ("/controls/fuel/tank/fuellines_filled",0, 3);
		}
	}
	#needs informations#if (CUTOFF1==1){
	#nterpolate ("controls/fuel/tank/fuellines_filled",0, 3);
	#}

	if (n12 < 60) {
		if (primepump2 > 24) {
			interpolate ("controls/fuel/tank[1]/fuellines_filled",1, 5);
		} else {
			interpolate ("controls/fuel/tank[1]/fuellines_filled",0, 3);
		}
	}
	#if (CUTOFF2 ==1){
	#interpolate ("controls/fuel/tank[1]/fuellines_filled",0, 3);
	#}

	settimer(primepumps, 0.1);
}
primepumps();


#####################################################

###Engine Start###

#controls.StartSelector = func(v = 1) {
 #   var vlt = getprop("systems/electrical/volts") or 0;
 #   if(vlt < 22) v=0;
#	setprop("controls/engines/engine/startselector",v);
#}

##starter cycle##
# var StartSelector
var start = func {

	var ignition1 = props.globals.getNode("/controls/engines/engine/ignition", 1);
	var ignition2 = props.globals.getNode("/controls/engines/engine[1]/ignition", 1);
	var starter1 = props.globals.getNode("/controls/engines/engine/starter", 1);
	var starter2 = props.globals.getNode("/controls/engines/engine[1]/starter", 1);
	var primepump1 = props.globals.getNode("/systems/electrical/outputs/prime-pump1").getValue() or 0;
	var primepump2 = props.globals.getNode("/systems/electrical/outputs/prime-pump1").getValue() or 0;
	var power1 = props.globals.getNode("controls/engines/engine/power", 1);
	var power2 = props.globals.getNode("controls/engines/engine[1]/power", 1);
	var starting1 = props.globals.getNode("controls/engines/engine/starting", 1);
	var starting2 = props.globals.getNode("controls/engines/engine[1]/starting", 1);
	var injection1 = props.globals.getNode("controls/engines/engine/injection", 1);
	var injection2 = props.globals.getNode("controls/engines/engine[1]/injection", 1);


	var CUTOFF = props.globals.getNode("/controls/engines/engine/cutoff").getValue() or 0;
	var n11 = props.globals.getNode("/engines/engine/n1-pct").getValue() or 0;
	var n12 = props.globals.getNode("/engines/engine[1]/n1-pct").getValue() or 0;
	var VOLTS = props.globals.getNode("/systems/electrical/volts").getValue() or 0;
	var SEL1 = props.globals.getNode("/controls/engines/engine/fadec/engine-state").getValue() or 0;
	var SEL2 = props.globals.getNode("/controls/engines/engine[1]/fadec/engine-state").getValue() or 0;



	if ((SEL1 == 1) and (n11 < 73.5)) {
		if (VOLTS > 22) {
			starter1.setValue (1);
		}
	} else {
		starter1.setValue (0);
	}

	if ((SEL2 == 1) and (n12 < 73.5)) {
		if (VOLTS > 22) {
			starter2.setValue (1);
		}
	} else {
		starter2.setValue (0);
	}

	###ignition cycle###

	if ((SEL1 == 1) and (n11 > 17) and (n11 < 73.5)) {
		if (VOLTS > 24) {
			ignition1.setValue (1);
		}
	} else {
		ignition1.setValue(0);
	}

	if ((n11 > 17) and (n11 < 73.5)) {
		starting1.setValue(1.0);
	}

	if ((SEL2 == 1) and (n12 > 17) and (n12 < 73.5)) {
		if (VOLTS > 24) {
			ignition2.setValue (1);
		}
	} else {
		ignition2.setValue(0);
	}

	if ((n12 > 17) and (n12 < 73.5)) {
		starting2.setValue(1.0);
	}

	settimer(start, 0.1);
}

start();



###fuel injection 1###

var injection1 = {
	init: func {

		var injection1 = props.globals.getNode("controls/engines/engine/injection", 1);
		var power1 = props.globals.getNode("controls/engines/engine/power", 1);

		var flines_filled1 = props.globals.getNode("controls/fuel/tank/fuellines_filled").getValue() or 0;
		var n11 = props.globals.getNode("/engines/engine/n1-pct").getValue() or 0;

		if (flines_filled1 > 0.90) {
			power1.setValue (0.13);
		} else {
			power1.setValue(0.0);
		}
		
		if ((n11 > 18) and (n11 < 73.5)) {
			injection1.setValue(1.0);
		}
	}
};

setlistener("controls/engines/engine[0]/starting", func {
	injection1.init();
});

###fuel injection 2###

var injection2 = {
	init: func {
		var injection2 = props.globals.getNode("controls/engines/engine[1]/injection", 1);
		var power2 = props.globals.getNode("controls/engines/engine[1]/power", 1);

		var flines_filled2 = props.globals.getNode("controls/fuel/tank[1]/fuellines_filled").getValue() or 0;
		var n12 = props.globals.getNode("/engines/engine[1]/n1-pct").getValue() or 0;

		if (flines_filled2 > 0.90) {
			power2.setValue (0.13);
		} else {
			power2.setValue(0.0);
		}
		
		if ((n12 > 18) and (n12 < 73.5)) {
			injection2.setValue(1.0);
		}
	}
};

setlistener("controls/engines/engine[1]/starting", func {
	injection2.init();
});



###idle 1###

var idle1 = {
	init: func {
		var power1 = props.globals.getNode("controls/engines/engine/power", 1);
		var flines_filled1 = props.globals.getNode("controls/fuel/tank/fuellines_filled").getValue() or 0;

		var n11 = props.globals.getNode("/engines/engine/n1-pct").getValue() or 0;
		var CUTOFF1 = props.globals.getNode("/controls/engines/engine/cutoff").getValue() or 0;
		var SEL1 = props.globals.getNode("/controls/engines/engine/fadec/engine-state").getValue() or 0;

		if (SEL1 == 1) {
			power1.setValue (0.74);
		}
	}
};

setlistener("controls/engines/engine/injection", func {
	idle1.init();
});


###idle2###
var idle2 = {
	init: func {
		var power2 = props.globals.getNode("controls/engines/engine[1]/power", 1);
		var flines_filled2 = props.globals.getNode("controls/fuel/tank[1]/fuellines_filled").getValue() or 0;

		var n12 = props.globals.getNode("/engines/engine[1]/n1-pct").getValue() or 0;
		var CUTOFF2 = props.globals.getNode("/controls/engines/engine[1]/cutoff").getValue() or 0;
		var SEL2 = props.globals.getNode("/controls/engines/engine[1]/fadec/engine-state").getValue() or 0;

		if (SEL2 == 1) {
			power2.setValue (0.74);
		}
	}
};

setlistener("controls/engines/engine[1]/injection", func {
	idle2.init();
});



###flight###

var flight = func {

	var flines_filled1 = props.globals.getNode("controls/fuel/tank/fuellines_filled").getValue() or 0;
	var flines_filled2 = props.globals.getNode("controls/fuel/tank[1]/fuellines_filled").getValue() or 0;

	var n11 = props.globals.getNode("/engines/engine/n1-pct").getValue() or 0;
	var n12 = props.globals.getNode("/engines/engine[1]/n1-pct").getValue() or 0;

	var power1 = props.globals.getNode("controls/engines/engine/power", 1);
	var power2 = props.globals.getNode("controls/engines/engine[1]/power", 1);

	var SEL1 = props.globals.getNode("/controls/engines/engine/fadec/engine-state").getValue() or 0;
	var SEL2 = props.globals.getNode("/controls/engines/engine[1]/fadec/engine-state").getValue() or 0;

	if ((n11 > 1) and (SEL1 == 2)) {
		power1.setValue(1);
	}

	if ((n11 > 1) and (flines_filled1 < 0.90)) {
		power1.setValue(0);
	}

	if ((n11 > 1) and (SEL1 == 0)) {
		power1.setValue(0);
	}

	if ((n12 > 1) and (SEL2 == 2)) {
		power2.setValue(1);
	}

	if ((n12 > 1) and (flines_filled2 < 0.90)) {
		power2.setValue(0);
	}

	if ((n12 > 1) and (SEL2 == 0)) {
		power2.setValue(0);
	}

	if ((n11 > 74.5) and (flines_filled1 >= 0.90) and (SEL1 == 1)) {
		power1.setValue(0.74);
	}

	if ((n12 > 74.5) and (flines_filled2 >= 0.90) and (SEL2 == 1)) {
		power2.setValue(0.74);
	}

	settimer(flight, 0.2);
}

flight();


var fadecEngine = {
    # handles to properties
    flines_filled: nil,
    primepump: nil,
    CUTOFF: nil,
    n1pct: nil,
    ignition2: nil,
    starter: nil,,
    power: nil,
    starting: nil,
    injection: nil,
    SEL: nil,
    VOLTS: nil,
    
    # timer object to have the main loop called on a regular basis
    timer: nil,
    
    # initialize handles and setup main loop
    init: func(engineNumber) {
        var e = props.globals.getNode("/controls/engines").getChild("engine", engineNumber, 1);
        me.flines_filled = props.globals.getNode("/controls/fuel/", 1).getChild("tank", engineNumber, 1).getNode("fuellines_filled", 1);
        me.primepump = props.globals.getNode("/systems/electrical/outputs/prime-pump" ~ (engineNumber + 1), 1);
        me.CUTOFF = e.getNode("cutoff", 1);
        me.n1pct = props.globals.getNode("/engines", 1).getChild("engine", engineNumber, 1).getNode("n1-pct", 1);
        me.ignition = e.getNode("ignition", 1);
        me.starter = e.getNode("starter", 1);
        me.power = e.getNode("power", 1);
        me.starting = e.getNode("starting", 1);
        me.injection = e.getNode("injection", 1);
        me.SEL = e.getNode("fadec/engine-state", 1);
        me.VOLTS = props.globals.getNode("/systems/electrical/volts", 1);
        
        timer = maketimer(0.1, me, me.run);
        timer.start();
    },
    
    # get values of all properties
    getValues: func() {
        var v = {};
        v.flines_filled = me.flines_filled.getValue() or 0;
        v.primepump = me.primepump.getValue() or 0;
        v.CUTOFF = me.CUTOFF.getValue() or 0;
        v.n1pct = me.n1pct.getValue() or 0;
        v.ignition = me.ignition.getValue() or 0;
        v.starter = me.starter.getValue() or 0;
        v.power = me.power.getValue() or 0;
        v.starting = me.starting.getValue() or 0;
        v.injection = me.injection.getValue() or 0;
        v.VOLTS = me.VOLTS.getValue() or 0;
        v.SEL = me.SEL.getValue() or 0;
        return v;
    },
    
    # main loop
    run: func() {
        var v = me.getValues();
    }
};

var engine_left = {parents:[fadecEngine] };
engine_left.init(0);

var engine_right = {parents:[fadecEngine] };
engine_right.init(1);



