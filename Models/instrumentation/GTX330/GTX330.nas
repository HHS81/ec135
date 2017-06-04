#code snippets taken from the Boeing CDU and KT-76C by Gary Neely

var GTX330_digits = ""; # string to hold the user input
var GTX330_code		= props.globals.getNode("/instrumentation/transponder/id-code", 1);
var GTX330_goodcode	= props.globals.getNode("/instrumentation/transponder/goodcode", 1);
var GTX330_mode = props.globals.getNode("/instrumentation/transponder/inputs/knob-mode", 1);

var stopwatchDialog = props.globals.getNode("/sim/gui/dialogs/stopwatch-dialog/", 1);
var instrumentLights = props.globals.getNode("/controls/lighting/instrument-lights");
var batterySwitch = props.globals.getNode("/controls/electric/battery-switch");

var savedBeforeVFR = -1; # The VFR-button saves the current code into this variable, so it can restore it when pressed again.

var VFRcode = "7000"; # 7000 is VFR in Europe. Change to 1200 to fit the US.

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


var pad_with_zeroes = func(num, size) {
  return substr("000000000" ~ num, -size);
}

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

var input = func(i) { # The user pressed the button for number i
    if (i <= 7) {
        GTX330_digits = GTX330_digits ~ i;
    }

    if (size(GTX330_digits) == 4) { # If we now have 4 digits, set the transponder code
        savedBeforeVFR = -1;
        GTX330_goodcode.setBoolValue(1);
        GTX330_code.setIntValue(GTX330_digits);
        GTX330_digits = "";
    }
}

var setMode = func(m) {
  # set the given mode for the transponder
  GTX330_mode.setDoubleValue(m);
}

var vfr = func {
    if (savedBeforeVFR == -1) {
        # Save the current code and set the code to VFR.
        if (GTX330_goodcode.getValue()) {
            savedBeforeVFR = pad_with_zeroes(GTX330_code.getValue(), 4);
        }
        GTX330_digits = VFRcode;
    } else {
        # Restore the saved code.
        GTX330_digits = savedBeforeVFR;
        savedBeforeVFR = -1;
    }

    GTX330_goodcode.setBoolValue(1);
    GTX330_code.setIntValue(GTX330_digits);
    GTX330_digits = "";
}

var clear = func {
  if (size(GTX330_digits) > 0) {
    # Remove the last digit
    GTX330_digits = left(GTX330_digits, size(GTX330_digits) - 1);
  } else {
    # Stop the stopwatch and reset it.
    var dlg = globals["__dlg:stopwatch-dialog"];
    if (dlg != nil) {
      dlg.stop();
      dlg.reset();
    } else {
      stopwatchDialog.setBoolValue("running", 0);
      stopwatchDialog.setDoubleValue("accu", 0);
    }
  }
}
	
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

var startstop = func {
    var dlg = globals["__dlg:stopwatch-dialog"];
    if (dlg != nil) {
        # the stopwatch dialog is open, we must use its functions
        if (dlg.running) {
            dlg.stop();
        } else {
            dlg.start();
        }
    } else {
        # the stopwatch dialog is closed, we must emulate its functions
        var r = stopwatchDialog.getNode("running");
        var running = (r != nil) ? r.getBoolValue() : 0;
        var time = props.globals.getNode("/sim/time/elapsed-sec");
        if (running) {
            var a = stopwatchDialog.getNode("accu");
            var accu = (a != nil) ? a.getValue() : 0.0;
            accu += time.getValue() - stopwatchDialog.getValue("start-time");
            a = stopwatchDialog.getNode("accu", 1);
            a.setDoubleValue(accu);
            r.setBoolValue(0);
        } else {
            running = 1;
            stopwatchDialog.setBoolValue("running", running);
            stopwatchDialog.setDoubleValue("start-time", time.getValue());
        }
    }
}

loop();
