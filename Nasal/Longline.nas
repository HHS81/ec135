#
 #This file is part of FlightGear, the free flight simulator
 #http://www.flightgear.org/

 #Copyright (C) 2017 Thorsten Renk, Wayne Bragg
 #Modified by Heiko Schulz

 #This program is free software; you can redistribute it and/or
 #modify it under the terms of the GNU General Public License as
 #published by the Free Software Foundation; either version 2 of the
 #License, or (at your option) any later version.

 #This program is distributed in the hope that it will be useful, but
 #WITHOUT ANY WARRANTY; without even the implied warranty of
 #MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 #General Public License for more details.
#

# 1 Gallon = 8.345404 lbs * 2500 = 20863 lbs

var capacity = 0.0;
var flex_angle_v_array = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var flex_angle_vr_array = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var flex_angle_r_array = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var onground_flag = 0;
var drop_flag = 0;

var Longline = func {
			

	var payload = getprop("sim/model/Longline/enabled");
	var paused = getprop("sim/freeze/clock");
	var crashed = getprop("sim/crashed");

	#var hopperweight = getprop("sim/weight[3]/weight-lb");
	var sniffer = 0.0;
	var overland = getprop("gear/gear/ground-is-solid");
	var altitude = getprop("position/altitude-agl-ft");

	var normalized = 1-(altitude-0)/(60-0);

	
			

	#################### flexhose ####################

	var alt_agl = altitude * 0.3048 + getprop("/sim/model/Longline/offset");
	var n_segments = 3;
	var segment_length = getprop("/sim/model/Longline/factor");

	if (overland)
		{
			if (alt_agl - n_segments * segment_length < 0.0)
			   {
				  onground_flag = 1;
			   }
			else
				  onground_flag = 0;
		} 
	else
		{
		   onground_flag = 0;
		}

	setprop("/sim/model/Longline/longlinehitsground", onground_flag);

	if (sniffer == 1) 
		{
			drop_flag = 50;
			return;
		}
	else
		if (drop_flag > 1 and !onground_flag)
			drop_flag -= 1;
		else
			{
				#setprop("sim/model/Longline/position-norm", 0);
				#sniffer = 0;
				drop_flag = 0;
			}

	var flex_force = getprop("/sim/model/Longline/flex-force");
	var damping = getprop("/sim/model/Longline/damping");
	var stiffness = getprop("/sim/model/Longline/stiffness");
	var sum_angle = 0.0;
	var sum_roll = 0.0;
	var dt = getprop("/sim/time/delta-sec");
	var bend_force = getprop("/sim/model/Longline/bendforce");
	var angle_correction = getprop("/sim/model/Longline/correction");

	if (onground_flag == 0)
		{
			if (drop_flag) 
				{
					var ax = drop_flag;
					var ay = 0;
					var az = -60;
				}
			else
				{
					var ax = getprop("/accelerations/pilot/x-accel-fps_sec");
					var ay = getprop("/accelerations/pilot/y-accel-fps_sec");
					var az = getprop("/accelerations/pilot/z-accel-fps_sec");
				}
		}
	else
		{
			var ax = 0;
			var ay = 0;
			var az = 0;
		}

	var a = math.sqrt(ax* ax + ay*ay + az*az);

	if (a==0.0) {a=1.0;}

	var ref_ang1 = math.asin(ax/a) * 180.0/math.pi;
	var ref_ang2 = math.asin(ay/a) * 180.0/math.pi;

	var damping_factor = math.pow(damping, dt);

	if (onground_flag == 0)
	   {

	   var current_angle = getprop("/sim/model/Longline/pitch1");
	   var ang_error = ref_ang1 - current_angle;

	   flex_angle_v_array[0] += ang_error * stiffness * dt;
	   flex_angle_v_array[0] *= damping_factor;

	   var ang_speed = flex_angle_v_array[0];

	   setprop("/sim/model/Longline/pitch1", current_angle + dt * ang_speed);
	   
	   
	   var current_roll = getprop("/sim/model/Longline/roll1");
	   var roll_error = ref_ang2 - current_roll;

	   flex_angle_r_array[0] += roll_error * stiffness * dt;
	   flex_angle_r_array[0] *= damping_factor;

	   var roll_speed = flex_angle_r_array[0];

	   setprop("/sim/model/Longline/roll1", current_roll + dt * roll_speed);

	  
	   # kink excitation
	   
	   #var kink =  -(next_roll - flex_angle_r_array[0]);
	   
	   #setprop("/sim/model/Longline/roll2",  kink) ;
	   #flex_angle_r_array[1] = kink;

	   }
	else
	   {

	   setprop("/sim/model/Longline/pitch1", ref_ang1);
	   setprop("/sim/model/Longline/roll1", ref_ang2);

	   }
#########################################################################
	var roll_target = 0.0;

	for (var i = 1; i< n_segments; i=i+1)
	   	{

	   	var gravity = n_segments - i;

		var uvelocity = getprop("/velocities/uBody-fps") - (drop_flag*2);
		var vvelocity = getprop("/velocities/vBody-fps") - (drop_flag*2);

		if (uvelocity == nil) {uvelocity = 0;}
		if (uvelocity > 500.0) {uvelocity = 500.0;}
		if (vvelocity == nil) {vvelocity = 0;}
		if (vvelocity > 500.0) {vvelocity = 500.0;}

		var dist_above_ground = alt_agl - (i+1) * segment_length;

		var uforce = flex_force * math.cos(sum_angle * math.pi/180.0) * 0.05 * (uvelocity/0.59);
		var vforce = flex_force * math.cos(sum_roll * math.pi/180.0) * 0.05 * (vvelocity/0.59);

		if (overland)
		{
		   if (dist_above_ground < 0.0)
			  {
			  uforce = uforce + bend_force * math.cos(sum_angle * math.pi/180.0);
			  vforce = vforce + bend_force * math.cos(sum_roll * math.pi/180.0);
			  }
		}

		if (uforce > 1.0 * gravity) {uforce = 1.0 * gravity;}
		if (vforce > 1.0 * gravity) {vforce = 1.0 * gravity;}

		var angle = - 180.0 /math.pi * math.atan2(uforce, gravity);#(uforce/gravity);
		sum_angle += angle;
		
		var roll = - 180.0 /math.pi * math.atan2(vforce, gravity);#(vforce/gravity);
		sum_roll += roll;
		
		if (onground_flag == 0)
		  {
		  current_angle = getprop("/sim/model/Longline/pitch"~(i+1));
		  ang_error = angle - current_angle;
		  
		current_roll = getprop("/sim/model/Longline/roll"~(i+1));
		  roll_error = roll - current_roll;
		 

		  flex_angle_v_array[i] += ang_error * stiffness * dt;
		  flex_angle_v_array[i] *= damping_factor;

		  ang_speed = flex_angle_v_array[i];

		  setprop("/sim/model/Longline/pitch"~(i+1), current_angle + dt * ang_speed);
		  
		  flex_angle_r_array[i] += roll_error * stiffness * dt;
		  flex_angle_r_array[i] *= damping_factor;

		  roll_speed = flex_angle_r_array[i];

		  setprop("/sim/model/Longline/roll"~(i+1), current_roll + dt * roll_speed);

		  }
		else
		  {
		  setprop("/sim/model/Longline/pitch"~(i+1), angle + angle_correction);
		  setprop("/sim/model/Longline/roll"~(i+1), roll + angle_correction);

		  }

		}
}

	# copy the current values into the last step array