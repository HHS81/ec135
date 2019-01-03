###

	#This file is part of FlightGear, the free flight simulator
	#http://www.flightgear.org/

	#Copyright (C) 2018/2019 Heiko Schulz, Heiko.H.Schulz@gmx.net

	#This program is free software; you can redistribute it and/or
	#modify it under the terms of the GNU General Public License as
	#published by the Free Software Foundation; either version 2 of the
	#License, or (at your option) any later version.

	#This program is distributed in the hope that it will be useful, but
	#WITHOUT ANY WARRANTY; without even the implied warranty of
	#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	#General Public License for more details.
    
    #following ground equipement stuff placing was done by Heiko Schuld and only possible by the help of the work by: Melchior Franz, Anders Gidenstam, Detelf Faber, onox. Thanks!
	
#helipad==============================================

var helipad_model = {
       index:   0,
       add:   func {
                          #print("helipad_model.add");
  var manager = props.globals.getNode("/models", 1);
                var i = 0;
                for (; 1; i += 1)
                   if (manager.getChild("model", i, 0) == nil)
                      break;

		var helipad = geo.aircraft_position().set_alt(
				props.globals.getNode("/position/ground-elev-m").getValue());

		geo.put_model("Aircraft/ec135/Models/Groundequipement/helipad-large-wood.xml", helipad,
				props.globals.getNode("/orientation/heading-deg").getValue());
		 me.index = i;
          },

       remove:   func {
                #print("helipad_model.remove");
             props.globals.getNode("/models", 1).removeChild("model", me.index);
          },
               
          
};

var init_common = func {
	setlistener("/sim/helipad/enable", func(n) {
		if (n.getValue()) {
				helipad_model.add();
		} else  {
			helipad_model.remove();
		}
	});
}
settimer(init_common,0);

#lift helipad========================================================

var lifthelipad = func {
        var lift = getprop("/sim/helipad/enable") or 0;
        
       if (lift>0){
       interpolate ("/sim/helipad/lift", 1, 3);
        }else{
        interpolate("/sim/helipad/lift", 0, 3);
        }  
settimer(lifthelipad, 0.1);
}
lifthelipad();



#ground-power======================================================


var gpu_model = {
       index:   0,
       add:   func {
                          #print("gpu_model.add");
  var manager = props.globals.getNode("/models", 1);
                var i = 0;
                for (; 1; i += 1)
                   if (manager.getChild("model", i, 0) == nil)
                      break;

		var gpu = geo.aircraft_position().set_alt(
				props.globals.getNode("/position/ground-elev-m").getValue());

		geo.put_model("Aircraft/ec135s/Models/Exterior/external-power.xml", gpu,
				props.globals.getNode("/orientation/heading-deg").getValue());
		 me.index = i;
          },

       remove:   func {
                #print("gpu_model.remove");
             props.globals.getNode("/models", 1).removeChild("model", me.index);
          },
};

var init_common = func {
	setlistener("/sim/gpu/enable", func(n) {
		if (n.getValue()) {
				gpu_model.add();
		} else  {
			gpu_model.remove();
		}
	});
}
settimer(init_common,0);


#safety-cones======================================================


var coneR_model = {
       index:   0,
       add:   func {
                          #print("coneR_model.add");
  var manager = props.globals.getNode("/models", 1);
                var i = 0;
                for (; 1; i += 1)
                   if (manager.getChild("model", i, 0) == nil)
                      break;
		var cones = geo.aircraft_position().set_alt(
				props.globals.getNode("/position/ground-elev-m").getValue());

		geo.put_model("Aircraft/ec135/Models/Groundequipement/safety-cone_R.ac", cones,
				props.globals.getNode("/orientation/heading-deg").getValue());
				 me.index = i;
          },

       remove:   func {
                #print("coneR_model.remove");
             props.globals.getNode("/models", 1).removeChild("model", me.index);
          },
};

var init_common = func {
	setlistener("/sim/coneR/enable", func(n) {
		if (n.getValue()) {
				coneR_model.add();
		} else  {
			coneR_model.remove();
		}
	});
}
settimer(init_common,0);

##

var coneL_model = {
       index:   0,
       add:   func {
                          #print("coneL_model.add");
  var manager = props.globals.getNode("/models", 1);
                var i = 0;
                for (; 1; i += 1)
                   if (manager.getChild("model", i, 0) == nil)
                      break;
		var cones = geo.aircraft_position().set_alt(
				props.globals.getNode("/position/ground-elev-m").getValue());

		geo.put_model("Aircraft/ec135/Models/Groundequipement/safety-cone_L.ac", cones,
				props.globals.getNode("/orientation/heading-deg").getValue());
				 me.index = i;
          },

       remove:   func {
                #print("coneL_model.remove");
             props.globals.getNode("/models", 1).removeChild("model", me.index);
          },
};

var init_common = func {
	setlistener("/sim/coneL/enable", func(n) {
		if (n.getValue()) {
				coneL_model.add();
		} else  {
			coneL_model.remove();
		}
	});
}
settimer(init_common,0);



#ground-power======================================================










#####################
# Adjust properties when in motion
# - external electrical disconnect when groundspeed higher than 0.1ktn (replace later with distance less than 0.01...)

ad = func {
    GROUNDSPEED = getprop("/velocities/groundspeed-kt") or 0;
    AGL         = getprop("/position/altitude-agl-ft")  or 0;

    if (GROUNDSPEED > 0.1) {
        setprop("/controls/electric/external-power", "false");
 
    }


    settimer(ad, 0.1);
}
init = func {
   settimer(ad, 0.0);
}

init();



##########################################
# Click Sounds
##########################################

var click = func (name, timeout=0.1, delay=0) {
    var sound_prop = "/sim/model/ec135/sound/click-" ~ name;

    settimer(func {
        # Play the sound
        setprop(sound_prop, 1);

        # Reset the property after 0.2 seconds so that the sound can be
        # played again.
        settimer(func {
            setprop(sound_prop, 0);
        }, timeout);
    }, delay);
};

##########################################
# Thunder Sound
##########################################

var speed_of_sound = func (t, re) {
    # Compute speed of sound in m/s
    #
    # t = temperature in Celsius
    # re = amount of water vapor in the air

    # Compute virtual temperature using mixing ratio (amount of water vapor)
    # Ratio of gas constants of dry air and water vapor: 287.058 / 461.5 = 0.622
    var T = 273.15 + t;
    var v_T = T * (1 + re/0.622)/(1 + re);

    # Compute speed of sound using adiabatic index, gas constant of air,
    # and virtual temperature in Kelvin.
    return math.sqrt(1.4 * 287.058 * v_T);
};

var thunder = func (name) {
    var thunderCalls = 0;

    var lightning_pos_x = getprop("/environment/lightning/lightning-pos-x");
    var lightning_pos_y = getprop("/environment/lightning/lightning-pos-y");
    var lightning_distance = math.sqrt(math.pow(lightning_pos_x, 2) + math.pow(lightning_pos_y, 2));

    # On the ground, thunder can be heard up to 16 km. Increase this value
    # a bit because the aircraft is usually in the air.
    if (lightning_distance > 20000)
        return;

    var t = getprop("/environment/temperature-degc");
    var re = getprop("/environment/relative-humidity") / 100;
    var delay_seconds = lightning_distance / speed_of_sound(t, re);

    # Maximum volume at 5000 meter
    var lightning_distance_norm = std.min(1.0, 1 / math.pow(lightning_distance / 5000.0, 2));

    settimer(func {
        var thunder1 = getprop("/sim/model/ec135/sound/click-thunder1");
        var thunder2 = getprop("/sim/model/ec135/sound/click-thunder2");
        var thunder3 = getprop("/sim/model/ec135/sound/click-thunder3");

        if (!thunder1) {
            thunderCalls = 1;
            setprop("/sim/model/ec135/sound/lightning/dist1", lightning_distance_norm);
        }
        else if (!thunder2) {
            thunderCalls = 2;
            setprop("/sim/model/ec135/sound/lightning/dist2", lightning_distance_norm);
        }
        else if (!thunder3) {
            thunderCalls = 3;
            setprop("/sim/model/ec135/sound/lightning/dist3", lightning_distance_norm);
        }
        else
            return;

        # Play the sound (sound files are about 9 seconds)
        click("thunder" ~ thunderCalls, 9.0, 0);
    }, delay_seconds);
};





##########################################
# Thunder sound
##########################################
setlistener("/sim/signals/fdm-initialized", func {
    # Listening for lightning strikes
    setlistener("/environment/lightning/lightning-pos-y", thunder);
});




###########
# INIT of Aircraft
# (states are initialized in separate nasal script!)
###########

setlistener("/sim/signals/fdm-initialized", func {
  
});
