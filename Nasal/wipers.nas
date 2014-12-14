# taken from b1900d



var Wiper = {
    new : func(prop,power,settings){
        m = { parents : [Wiper] };
        m.direction = 1;
        m.delay_count = 0;
        m.spd_factor = 0;
        m.speed_prop=[];
        m.delay_prop=[];
        m.node = props.globals.getNode(prop,1);
        m.power = props.globals.getNode(power,1);
        if(m.power.getValue()==nil)m.power.setDoubleValue(0);
        m.position = m.node.getNode("position-norm", 1);
        m.position.setDoubleValue(0);
        m.switch = m.node.getNode("switch", 1);
        m.switch.setIntValue(0);
        for(var i=0; i<settings; i+=1) {
            append(m.speed_prop,m.node.getNode("arc-sec["~i~"]",1));
            if(m.speed_prop[i].getValue()==nil)m.speed_prop[i].setDoubleValue(i);
            append(m.delay_prop,m.node.getNode("delay-sec["~i~"]",1));
            if(m.delay_prop[i].getValue()==nil)m.delay_prop[i].setDoubleValue(i * 0.5);
        }
	
        return m;
    },
    
	
    
    
    
    active: func{
    if(me.power.getValue()<=5)return;
    var sw=me.switch.getValue();
    var sec =getprop("/sim/time/delta-sec");
    var spd_factor = 1/me.speed_prop[sw].getValue();
    var pos = me.position.getValue();
    if(sw==0){
        spd_factor = 1/me.speed_prop[1].getValue();
        if(pos <=0.45){
        me.position.setValue(0.45);
        return;
        }
    } 
    
    

    if(pos >=1.000){
        me.direction=-1;
        }elsif(pos <=0){
            me.direction=1;
            var dly=me.delay_prop[sw].getValue();
            if(dly>0){
                me.direction=0;
                me.delay_count+=sec;
                if(me.delay_count >= dly){
                    me.delay_count=0;
                    me.direction=1;
                }
            }
        }
    var wiper_time = spd_factor*sec;
    pos =pos+(wiper_time * me.direction);
    me.position.setValue(pos);
    }
};

var passive = func{

var pos = props.globals.getNode("/controls/electric/wiper/position-norm",1);
var swt = props.globals.getNode("/controls/electric/wiper/switch").getValue() or 0;
var pwr = props.globals.getNode("systems/electrical/volts").getValue() or 0;

if (pwr <20){
pos.setDoubleValue(0.45);
}

settimer(passive, 0);
}

passive();


var wiper = Wiper.new("controls/electric/wiper","systems/electrical/volts",3);


setlistener("/sim/signals/fdm-initialized", func {
    settimer(update_systems, 2);
});

var update_systems = func {
        power = getprop("/controls/switches/master-panel");
        volts = getprop("/systems/electrical/volts");
    wiper.active();

    
    
    settimer(update_systems, 0);
}
