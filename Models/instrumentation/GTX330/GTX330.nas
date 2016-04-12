#code snippets taken from the Boeing CDU and KT-76C by Gary Neely

GTX330Input             = props.globals.getNode("/instrumentation/GTX330/input", 1);
GTX330_code	 = props.globals.getNode("/instrumentation/transponder/id-code", 1);
GTX330_goodcode	 = props.globals.getNode("/instrumentation/transponder/goodcode", 1);

var GTX330_code		= props.globals.getNode("/instrumentation/transponder/id-code");
var GTX330_Input             = props.globals.getNode("/instrumentation/GTX330/input");
var GTX330_goodcode	= props.globals.getNode("/instrumentation/transponder/goodcode");
var GTX330_mode = props.globals.getNode("/instrumentation/transponder/inputs/knob-mode", 1);

var stopwatchDialog = props.globals.getNode("/sim/gui/dialogs/stopwatch-dialog/", 1);
var instrumentLights = props.globals.getNode("/controls/lighting/instrument-lights");
var batterySwitch = props.globals.getNode("/controls/electric/battery-switch");

var GTX330_codes		= [];						# Array for 4 code digits
var GTX330_last		= [];						# Holds copy of last known good code

var mode_texts = {
  0 : "(off)",
  1 : "STBY",
  2 : "(test)",
  3 : "(ground)",
  4 : "ON",
  5 : "ALT"
};

var display_colors = {
  "off"      : [   0,   0,   0], # color when the display is off, e.g. the battery master switch is OFF (usually black)
  "active"   : [   1,   1,   0], # color of an active pixel (yellow)
  "inactive" : [ 0.1, 0.1, 0.1]  # color of an inactive pixel (dark grey, inactive pixels are usually not completely black)
};


# Create a canvas
var GTX330Display_canvas = canvas.new({
  "name": "GTX330Display",
  "size": [512, 128],
  "view": [202,  48]
});

# Place the canvas on all objects called "GTX330Display"
GTX330Display_canvas.addPlacement({"node": "GTX330Display"});

# Create the elements to draw on the canvas.
var GTX330Display_group = GTX330Display_canvas.createGroup();

var canvas_elements = {};

canvas_elements["flighttime"] = GTX330Display_group.createChild("text")
                                                   .setTranslation(134, 37)
                                                   .setAlignment("left-bottom")
                                                   .setFont("LiberationFonts/LiberationMono-Bold.ttf")
                                                   .setFontSize(17, 1.2)
                                                   .setText("99:99:99");

canvas_elements["flighttime_label"] = GTX330Display_group.createChild("text")
                                                         .setTranslation(133, 20)
                                                         .setAlignment("left-bottom")
                                                         .setFont("LiberationFonts/LiberationMono-Regular.ttf")
                                                         .setFontSize(11, 1.05)
                                                         .setText("FLIGHT TIME");

canvas_elements["squawk"] = GTX330Display_group.createChild("text")
                                               .setTranslation(43, 35)
                                               .setAlignment("left-bottom")
                                               .setFont("LiberationFonts/LiberationMono-Bold.ttf")
                                               .setFontSize(34, 0.95)
                                               .setText("----");

canvas_elements["mode"] = GTX330Display_group.createChild("text")
                                             .setTranslation(2, 27)
                                             .setAlignment("left-bottom")
                                             .setFont("LiberationFonts/LiberationMono-Bold.ttf")
                                             .setFontSize(10, 1)
                                             .setText("INIT");


var updateDisplay = func {
  m = (GTX330_mode.getValue() or 0);
  fg_color = (instrumentLights.getValue() or 0) ? "active" : "inactive";
  bg_color = (instrumentLights.getValue() or 0) ? "inactive" : "active";
  bat = (batterySwitch.getValue() or 0);
  canvas_elements["mode"].setText(mode_texts[m]);
  if ((m == 0) or !bat) {
    GTX330Display_group.hide();
    bg_color = "off";
  } else {
    GTX330Display_group.show().setColor(display_colors[fg_color]);
  }
  GTX330Display_canvas.setColorBackground(display_colors[bg_color]);
}

var updateDisplayedCode = func {
  canvas_elements["squawk"].setText(sprintf("%04d", GTX330_code.getValue()));
}


### Workaround, until https://sourceforge.net/p/flightgear/fgdata/merge-requests/60/ is merged.
### React directly to changes in the "Radio Frequencies" dialog.
var onTransponderDigitsChanged = func {
  var goodcode = 1;
  var code = 0;
  for (var i = 3; i >= 0 ; i -= 1) {
    goodcode = goodcode and (num(getprop("/instrumentation/transponder/inputs/digit[" ~ i ~ "]")) != nil) ;
    code = code * 10 + (num(getprop("/instrumentation/transponder/inputs/digit[" ~ i ~ "]")) or 0);
  }
  if (goodcode) {
    canvas_elements["squawk"].setText(sprintf("%04d", code));
  }
}
for (var i = 0; i<4; i += 1) {
  setlistener(props.globals.getNode("/instrumentation/transponder/inputs/digit[" ~ i ~ "]", 1), onTransponderDigitsChanged);
}
### End of workaround

updateDisplay();
updateDisplayedCode();
setlistener(GTX330_mode, updateDisplay, 0, 0);
setlistener(instrumentLights, updateDisplay, 0, 0);
setlistener(batterySwitch, updateDisplay, 0, 0);
setlistener(GTX330_code, updateDisplayedCode, 0, 1);

var input = func(i) {
		#setprop("/instrumentation/GTX330/input",getprop("/instrumentation/GTX330/input")~i);
  append(GTX330_codes,i);
GTX330_copycode();

 if (size(GTX330_codes) >= 4) { return 0; }
 if (size(GTX330_codes) == 4) {						# If we now have 4 digits, treat as a good
   GTX330_last = GTX330_codes;						# code and save; flag that we have a good
    GTX330_goodcode.setValue(1);	
}  else {
    GTX330_goodcode.setValue(0);
  }
 GTX330_copycode();
}

var delete = func {
  if (size(GTX330_codes)) {
    pop(GTX330_codes);
    GTX330_copycode();
  }
}
	


var GTX330_copycode = func {
#var GTX330_Input             = props.globals.getNode("/instrumentation/GTX330/input");
  if (!size(GTX330_codes)) {
    GTX330_code.setValue(0);
    return 0;
  }
  var codestr = "";
  for(var i=0; i < size(GTX330_codes); i+=1) {
    codestr = codestr ~ GTX330_codes[i];
  }
  var code = 0;
  code = code + codestr;
  GTX330_code.setValue(code);
}


	
#var delete = func {
#		var length = size(getprop("/instrumentation/GTX330/input")) - 1;
#		setprop("/instrumentation/GTX330/input",substr(getprop("/instrumentation/GTX330/input"),0,length));
#	}
	
var i = 0;

var timestring = func(seconds) {
    var h = seconds / 3600;
    var m = int(math.mod(seconds / 60, 60));
    var s = int(math.mod(seconds, 60));
    var d = sprintf("%02d:%02d:%02d", h, m, s);
    return d;
}

var loop = func {
    var running = stopwatchIsRunning();
    var display = stopwatchAccu();
    var time = props.globals.getNode("/sim/time/elapsed-sec");
    if (running) {
        display += time.getValue() - stopwatchStartTime();
    }
    canvas_elements["flighttime"].setText(timestring(display));

    settimer(loop, 0.33333);
}

var plusminus = func {	
	var end = size(getprop("/instrumentation/GTX/input"));
	var start = end - 1;
	var lastchar = substr(getprop("/instrumentation/GTX/input"),start,end);
	if (lastchar == "+"){
		me.delete();
		me.input('-');
		}
	if (lastchar == "-"){
		me.delete();
		me.input('+');
		}
	if ((lastchar != "-") and (lastchar != "+")){
		me.input('+');
		}
	}
	
# Return true if the stopwatch is running, false otherwise.
var stopwatchIsRunning = func {
    var dlg = globals["__dlg:stopwatch-dialog"];
    if (dlg != nil) {
        return dlg.running
    } else {
        var r = stopwatchDialog.getValue("running");
        return (r != nil) ? r : 0;
    }
}

# Return the number of seconds in the stopwatch accumulator.
var stopwatchAccu = func {
    var dlg = globals["__dlg:stopwatch-dialog"];
    if (dlg != nil) {
        return dlg.accu
    } else {
        var a = stopwatchDialog.getValue("accu");
        return (a != nil) ? a : 0.0;
    }
}

# Return the time the stopwatch was started. The result is undefined if the stopwatch is not running.
var stopwatchStartTime = func {
    var dlg = globals["__dlg:stopwatch-dialog"];
    if (dlg != nil) {
        return dlg.start_time
    } else {
        return stopwatchDialog.getValue("start-time");
    }
}


loop();
