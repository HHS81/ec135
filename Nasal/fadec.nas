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


#simpel hack- known issue: boost-pump runs even without power#


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
        setlistener(me.starting, func {
            me.onStarting();
        });
        setlistener(me.injection, func {
            me.onInjection();
        });
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
        
        # filling the fuellines
        if (v.n1pct < 60) {
            if (v.primepump > 24) {
                interpolate(me.flines_filled, 1, 5);
            } else {
                interpolate(me.flines_filled, 0, 3);
            }
        }
        
        # starter cycle
        if ((v.SEL >= 1) and (v.n1pct < 73.5) and (v.VOLTS > 22)) {
            me.starter.setValue(1);
        } else {
            me.starter.setValue(0);
        }
        
        # ignition cycle
        if ((v.n1pct > 17) and (v.n1pct < 73.5) and (v.SEL >= 1) and (v.VOLTS > 24)) {
            me.ignition.setValue(1);
        } else {
            me.ignition.setValue(0);
        }
        
        if ((v.n1pct > 17) and (v.n1pct < 73.5)) {
            me.starting.setValue(1.0);
        }
        
        # flight
        if ((v.n1pct > 1) and (v.SEL == 2)) {
            me.power.setValue(1);
        }
        
        if ((v.n1pct > 1) and (v.flines_filled < 0.90)) {
            me.power.setValue(0);
        }
        
        if ((v.n1pct > 1) and (v.SEL == 0)) {
            me.power.setValue(0);
        }
        
        if ((v.n1pct > 74.5) and (v.flines_filled >= 0.90) and (v.SEL == 1)) {
            me.power.setValue(0.74);
        }
    },
    
    onStarting: func() {
        var v = me.getValues();
        
        if (v.flines_filled > 0.90) {
            me.power.setValue(0.13);
        } else {
            me.power.setValue(0.0);
        }
        if ((v.n1pct > 18) and (v.n1pct < 73.5)) {
            me.injection.setValue(1.0);
        }
    },
    
    onInjection: func() {
        var v = me.getValues();
        
        if (v.SEL >= 1) {
            me.power.setValue(0.74);
        }
    }
};

var engine_left = {parents:[fadecEngine] };
engine_left.init(0);

var engine_right = {parents:[fadecEngine] };
engine_right.init(1);



