

var p = "/sim/model/ec130/flight-duration/";
			var display = props.globals.getNode(p ~ "display", 1);
			var time = props.globals.getNode("/sim/time/elapsed-sec");
                        var n1 = props.globals.getNode("/engines/engine/n1-pct").getValue() or 0;
			var bg = props.globals.getNode("/sim/model/ec135/flight-duration", 1);
			var trig = props.globals.getNode("controls/engines/engine[0]/fadec/engine-state").getValue() or 0;
			
			
			
			var start_time = props.globals.getNode(p ~ "start-time", 1).getValue();
			var accu = props.globals.getNode(p ~ "accu", 1).getValue();
			if (start_time == nil)
				start_time = 0;
			if (accu == nil)
				accu = 0;

			var r = props.globals.getNode(p ~ "running");
			var running = r != nil ? r.getBoolValue() : 0;


			var begin = func {
                         var n1 = props.globals.getNode("/engines/engine/n1-pct").getValue() or 0;

			if ((n1 >60) and (!running)) {
					start_time = time.getValue();
					running = 1;
					loop();
				}
					
				
			settimer(begin, 0.1);
}
begin();

			var stop = func {
			var n1 = props.globals.getNode("/engines/engine/n1-pct").getValue() or 0;
				if ((n1 < 50) and (running)) {
					running = 0;
					show(accu += time.getValue() - start_time);
				}
			settimer(stop, 0.1);
}
stop();

			var reset = func{
			var trig = props.globals.getNode("controls/engines/engine[0]/fadec/engine-state").getValue() or 0;
			var n1 = props.globals.getNode("/engines/engine/n1-pct").getValue() or 0;
			accu = 0;
				if ((trig >0) and (n1 >50) and (n1<60)){
				show(0);}
			settimer(reset, 0.1);
}
reset();
			
			
						

			var loop = func {
				if (running) {
					show(time.getValue() - start_time + accu);
					settimer(loop, 0.02);
				}
			}
####OSGtext seems not to read var d. So work around####

			var show = func(s) {
			        var display_hr = props.globals.getNode("/sim/model/ec135/flight-duration/hr", 1);
				var display_mn = props.globals.getNode("/sim/model/ec135/flight-duration/mn", 1);
				var hours = s / 3600;
				var minutes = int(math.mod(s / 60, 60));
				var seconds = int(math.mod(s, 60));
				var msec = int(math.mod(s * 1000, 1000) / 100);
				var d = sprintf("%3d  %02d ", hours, minutes);
				display_hr.setValue(hours);
				display_mn.setValue(minutes);
			}

			if (running) {
				loop();
			} else {
				if (accu == nil)
					accu = 0;
				show(accu);
			}
			
props.globals.getNode(p ~ "start-time", 1).setDoubleValue(start_time);
			props.globals.getNode(p ~ "running", 1).setBoolValue(running);
			props.globals.getNode(p ~ "accu", 1).setDoubleValue(accu);
			running = 0;	# stop display loop



#########################################

#var last_fltn = 0;
var trigger =0;

var flightnumber = {

init:func{
var last_fltn = props.globals.getNode("/sim/model/ec135/flightnumber").getValue() or 0;
#var trigger = props.globals.getNode("controls/engines/engine[0]/fadec/engine-state").getValue() or 0;
var fltn = props.globals.getNode("/sim/model/ec135/flightnumber", 1);
var n1 = props.globals.getNode("/engines/engine/n1-pct").getValue() or 0;

if (n1>60)
trigger=1;

var count_fltn = (last_fltn + trigger);

fltn.setValue(count_fltn);
trigger=0;

last_fltn = count_fltn;
}
};
setlistener("controls/engines/engine[0]/fadec/engine-state", func {
flightnumber.init();

});

