

pilotDoor = aircraft.door.new( "/sim/model/door-positions/pilotDoor", 1, 0 );
copilotDoor = aircraft.door.new( "/sim/model/door-positions/copilotDoor", 1, 0 );
rearDoors = aircraft.door.new( "/sim/model/door-positions/rearDoors", 2, 0 );
ribackDoor = aircraft.door.new( "/sim/model/door-positions/ribackDoor", 1.5, 0 );
lebackDoor = aircraft.door.new( "/sim/model/door-positions/lebackDoor", 1.5, 0 );

# engines/rotor =====================================================
var state = props.globals.getNode("sim/model/ec135/state");
var rotor = props.globals.getNode("controls/engines/engine/magnetos");
var rotor_rpm = props.globals.getNode("rotors/main/rpm");
var torque = props.globals.getNode("rotors/gear/total-torque", 1);
var collective = props.globals.getNode("controls/engines/engine/throttle");
var turbine = props.globals.getNode("sim/model/ec135/turbine-rpm-pct", 1);
var torque_pct = props.globals.getNode("sim/model/ec135/torque-pct", 1);
var stall = props.globals.getNode("rotors/main/stall", 1);
var stall_filtered = props.globals.getNode("rotors/main/stall-filtered", 1);


# 0 off
# 1 startup sound in progress
# 2 sound loop
# 3 shutdown sound in progress

engines = func {
	s = state.getValue();
	if (arg[0] == 1) {
		if (s == 0) {
			state.setValue(1);				# engines started
			settimer(func { rotor.setValue(1) }, 3);
			interpolate(turbine, 100, 25);
			settimer(func { state.setValue(2) }, 10.5);	# -> engines running
		}
	} else {
		if (s == 2) {
			rotor.setValue(0);				# engines stopped
			state.setValue(3);
			interpolate(turbine, 0, 18);
			settimer(func { state.setValue(0) }, 25);	# -> engines off
		}
	}
}
# torquemeter
var torque_val = 0;
torque.setDoubleValue(0);

set_torque = func(dt) {
	var f = dt / (0.2 + dt);
	torque_val = torque.getValue() * f + torque_val * (1 - f);
	torque_pct.setDoubleValue(torque_val / 5300);
}



# stall sound
var stall_val = 0;
stall.setDoubleValue(0);

set_stall = func(dt) {
	var s = stall.getValue();
	if (s < stall_val) {
		var f = dt / (0.3 + dt);
		stall_val = s * f + stall_val * (1 - f);
	} else {
		stall_val = s;
	}
	var c = collective.getValue();
	stall_filtered.setDoubleValue(stall_val + 0.006 * (1 - c));
}

# "manual" rotor animation for flight data recorder replay ============
var rotor_step = props.globals.getNode("sim/model/ec135/rotor-step-deg");
var blade1_pos = props.globals.getNode("rotors/main/blade[0]/position-deg", 1);
var blade2_pos = props.globals.getNode("rotors/main/blade[1]/position-deg", 1);
var blade3_pos = props.globals.getNode("rotors/main/blade[2]/position-deg", 1);
var blade4_pos = props.globals.getNode("rotors/main/blade[3]/position-deg", 1);
var rotorangle = 0;

rotoranim_loop = func {
	i = rotor_step.getValue();
	if (i >= 0.0) {
		blade1_pos.setValue(rotorangle);
		blade2_pos.setValue(rotorangle + 90);
		blade3_pos.setValue(rotorangle + 180);
		blade4_pos.setValue(rotorangle + 270);
		rotorangle += i;
		settimer(rotoranim_loop, 0.1);
	}
}




init_rotoranim = func {
	if (rotor_step.getValue() >= 0.0) {
		settimer(rotoranim_loop, 0.1);
	}
}

# strobe and light=====
var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("sim/model/lights/strobe/state", [0.025, 1.00], strobe_switch);

