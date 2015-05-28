#
# AFCS configuration for OH-1
# This is an example for showing how to tweak AFCS configuration so I wrote many parameters.
# You don't have to write all the parameters but write just what you want to change.

var fcs_params = {
  'gains' : {
  'sensitivities' : {
        'pitch' : 20, 
          'roll' : 30, 
        'yaw' : 5, 
  },
  'sas' : {
	'authority-limit' : 0.15,
        'pitch' : -0.015, 
          'roll' : 0.00075, 
        'yaw' : 0.0075, 
  },
    'cas' : {
      'input' : {
        'roll' : 60, 
        'pitch' : -60, 
        'yaw' : 30, 
        'attitude-roll' : 80, 
        'attitude-pitch' : -80, 
        'anti-side-slip-min-speed' : 0.015
      },
      'output' : {
        'roll' : 0.03, 
        'pitch' : -0.1, 
        'yaw' : 0.5, 
        'roll-brake-freq' : 5, 
        'pitch-brake-freq' : 2, 
        'roll-brake' : 0.8, 
        'pitch-brake' : 12, 
        'anti-side-slip-gain' : -4.5,
        'heading-adjuster-gain' : -5,
        'heading-adjuster-limit' : 5 
      }
    },
    'tail-rotor' : { 
      'src-minimum' : 0.10, 
      'src-maximum' : 1.00, 
      'low-limit'   : 0.00011, 
      'high-limit'  : 0.0035, 
      'error-adjuster-gain' : -0.5
    },
    'stabilator' : { 
                     #   0    10   20    30   40   50   60   70   80   90  100  110  120  130  140  150  160, 170, 180, .....
      'gain-table' : [-0.9, -0.8, 0.1, -0.5, 0.0, 0.7, 0.8, 0.9, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.9, 0.8, 0.4, 0.2, 0.2, -1.0]
    }
  },
  'switches' : { # initial status of FCS
    'auto-hover' : 0, 
    'cas' : 1, 
    'sas' : 1, 
    'attitude-control' : 1,
    'auto-stabilator' : 0, 
    'sideslip-adjuster' : 0, 
    'tail-rotor-adjuster' : 0,
    'heading-adjuster' : 0,
    'debug' : 1  # Add this only when you are adjusting FCS parameters
  }
};
    
var setAFCSConfig = func() {
  var confNode = props.globals.getNode("/controls/flight/fcs", 1);
  confNode.setValues(fcs_params);
  # This invokes fcs.initialize() 
  setprop("/sim/signals/fcs-initialized", 1);
}

setlistener("/sim/signals/fdm-initialized", setAFCSConfig);

#
# This will reinitialize the parameters in reinitializing FG.
#
setlistener("/sim/signals/reinit", func {
    var confNode = props.globals.getNode("/controls/flight/fcs", 1);
    confNode.setValues(fcs_params);
  });

