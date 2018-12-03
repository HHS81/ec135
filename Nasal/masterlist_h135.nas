# --------------------------------
#
# driver functions for FND masterlist messages
#
# this is the aircraft specfic part of the 
# masterlist driver containing the 
# aircraft specifc definitions
# --------------------------------

#  ENG1    STARTER ON     ENG2
#  ENG1      FAIL         ENG2  : n1 < 95% and pow ==1 and running
#  ENG1      IDLE         ENG2  : pow ==.74 and 0.6<n1<.7 and running
#  FUEL1  PRIME PUMP ON   FUEL2
#  FUEL1  PRESSURE        FUEL2 : no fuel press: supply empty, prime pump off when n1<50
#  ENG1  OIL HIGH TEMP    ENG2
#  ENG1  OIL HIGH PRESS   ENG2
#  ENG1  OIL LOW PRESS    ENG2
#        MGB LOW PRESS
#         DOOR OPEN
#         ROTOR BRAKE 
#          SL LIGHT

var between = func (a,b,c) {if (a!=nil and b!=nil and c!=nil) return (a>b and a<c) else return 0;}

stime = props.globals.getNode("/sim/time/elapsed-sec");
var mfdroot = "/instrumentation/efis/";

tlo = props.globals.getNode(mfdroot ~ "vmd/oilt-caution-lo-degc");
thi = props.globals.getNode(mfdroot ~ "vmd/oilt-caution-hi-degc");
plo = props.globals.getNode(mfdroot ~ "vmd/oilp-caution-lo-bar");
phi = props.globals.getNode(mfdroot ~ "vmd/oilp-caution-hi-bar");
mgbpress = props.globals.getNode("/rotors/gear/mgb-oil-pressure-bar",1);
training = props.globals.getNode("/controls/switches/ecp/trainswitch",1);
trainingabort = props.globals.getNode("/instrumentation/efis/vmd/training-aborted",1);

prime = [props.globals.getNode("/controls/fuel/tank[1]/prime-pump",1),
         props.globals.getNode("/controls/fuel/tank[2]/prime-pump",1)];
st = [   props.globals.getNode("/controls/engines/engine[0]/starter"),
         props.globals.getNode("/controls/engines/engine[1]/starter")];
pw = [   props.globals.getNode("/controls/engines/engine[0]/power",1),
         props.globals.getNode("/controls/engines/engine[1]/power",1)];
run = [ props.globals.getNode("/engines/engine[0]/running",1),
         props.globals.getNode("/engines/engine[1]/running",1)];
n1 = [   props.globals.getNode("/engines/engine[0]/n1-pct",1),
         props.globals.getNode("/engines/engine[1]/n1-pct",1)];
oilp = [ props.globals.getNode("/engines/engine[0]/oil-pressure-bar",1),
         props.globals.getNode("/engines/engine[1]/oil-pressure-bar",1)];
oilt = [ props.globals.getNode("/engines/engine[0]/oil-temperature-degc",1),
         props.globals.getNode("/engines/engine[1]/oil-temperature-degc",1)];
fu   = [ props.globals.getNode("/consumables/fuel/tank[0]/level-norm",1),
         props.globals.getNode("/consumables/fuel/tank[1]/level-norm",1),
         props.globals.getNode("/consumables/fuel/tank[2]/level-norm",1)];
xfer = [props.globals.getNode("/controls/switches/fuel/transfer-pump[0]",1),
         props.globals.getNode("/controls/switches/fuel/transfer-pump[1]",1)];

ecp = [props.globals.getNode("/controls/switches/ecp/pos[0]",1),
       props.globals.getNode("/controls/switches/ecp/pos[1]",1)];

doors = [ 
    props.globals.getNode("/sim/model/ec135/door-positions/leftBackDoor/position-norm"),
    props.globals.getNode("/sim/model/ec135/door-positions/leftFrontDoor/position-norm"),
    props.globals.getNode("/sim/model/ec135/door-positions/rightBackDoor/position-norm"),
    props.globals.getNode("/sim/model/ec135/door-positions/rightFrontDoor/position-norm"),
    props.globals.getNode("/sim/model/ec135/door-positions/rightRearDoor/position-norm"),
    props.globals.getNode("/sim/model/ec135/door-positions/leftRearDoor/position-norm")
    ];

sl  = props.globals.getNode("/lightpack/search-lights-intensity");
ll  = props.globals.getNode("/lightpack/landing-lights-intensity");
hoist  = props.globals.getNode("/sim/model/rescue-lift",1);
floats = props.globals.getNode("/controls/gear/floats-armed");

var dooropen = func { 
 op=0;
 foreach (var d; doors) {
   if (d.getValue() != nil) op+=d.getValue();
 }
 return (op>0);
}

rotorb = props.globals.getNode("/controls/rotor/brake");

var rotorbron = func { 
 x = rotorb.getValue();
 if (x == nil) 
    return 0;
 return (x>0);
}

var fuelp = func (i) {
  x = n1[i].getValue(); 
  # check if engine i running or starting but no fuel feed from supply tank i
  if (x == nil or !ecp_get(i) ) 
    return 0;
  return (  
         ( x < 50 and !prime[i].getValue() ) or fu[i+1].getValue() < 0.01    
         );
};

var ecp_get = func (i) { 
 x = ecp[i].getValue();
 if (x == nil) 
    return 0;
 return (x>0);
};


eng = ["ENG1", "ENG2"];

#initalize the masterlist object with root node

ml = masterlist.new(mfdroot ~ "fnd/masterlist");

#
# register the function objects to test the conditions for
# diplaying messages in the master list:
#	
# masterlist.register(func condition, column, message, LH/RH text)

# Information messages

#ml.info(func {return between(hoist.getValue(), 0.01, 99);},  2,    "      HOIST","");
#ml.info(func {return sl.getValue()>0 and ll.getValue()==0;},  2,   "    SL LIGHT","");
#ml.info(func {return sl.getValue()>0 and ll.getValue()>0;},  2,    "  FXD+SL LIGHT","");
#ml.info(func {return sl.getValue()==0 and ll.getValue()>0;},  2,   "    FXD LIGHT","");
#ml.info(func {return between(stime.getValue(), 0, 34);},  2,       "    PWR-UP TST","");
#ml.info(func {return between(stime.getValue(), 34, 39);},  2,      "  PWR-UP TST OK","");
#ml.info(func {return floats.getValue()==1;},  2,      "  FLOATS ARMED","");

# Advisory messages
xtime = rand()*50;
if (xtime>15) ml.advisory(func {return between(stime.getValue(),xtime ,xtime+3 );},  2, "DOWNLOAD FAILED","");

# Caution messages

ml.caution(func {return dooropen();},  2,   "   DOOR OPEN","");
ml.caution(func {return rotorbron();}, 2,   "  ROTOR BRAKE", "");
ml.caution(func {return st[0].getValue();}, 0, "   STARTER ON", eng[0]);
ml.caution(func {return st[1].getValue();}, 1, "   STARTER ON", eng[1]);
ml.caution(func {return training.getValue();}, 0, "  TRAINING", eng[0]);
ml.caution(func {return trainingabort.getValue();}, 2, "TRAINING ABORTED", "");

ml.caution(func {return between(n1[0].getValue(),60,70) and between(pw[0].getValue(),0.6,0.7); },
             0, "        IDLE", eng[0]);
ml.caution(func {return between(n1[1].getValue(),60,70) and between(pw[1].getValue(),0.6,0.7); },
             1, "        IDLE", eng[1]);

ml.caution(func {return prime[0].getValue();},0, "  PRIME PUMP", "FUEL1");
ml.caution(func {return prime[1].getValue();},1, "  PRIME PUMP", "FUEL2");

ml.caution(func {fuelp(0); },0, "   PRESSURE", "FUEL1");
ml.caution(func {fuelp(1); },1, "   PRESSURE", "FUEL2");

#ml.caution(func {return ((xfer[0].getValue() == 0) and (ecp_get(0) or ecp_get(1)) ); },0, "  FUEL PUMP", "FWD");
#ml.caution(func {return ((xfer[1].getValue() == 0) and (ecp_get(0) or ecp_get(1)) ); },1, "  FUEL PUMP", "AFT");

ml.caution(func {return between(oilt[0].getValue(),-99,0) or between(oilp[0].getValue(),phi.getValue()-0.2,phi.getValue());},
             0, " OIL OVERLIMT", eng[0]);
ml.caution(func {return between(oilt[1].getValue(),-99,0) or between(oilp[1].getValue(),phi.getValue()-0.2,phi.getValue());},
             1, " OIL OVERLIMT", eng[1]);
ml.caution(func {return !between(oilt[0].getValue(),tlo.getValue(),thi.getValue()) and run[0].getValue();},
             0, "    OIL TEMP", eng[0]);
ml.caution(func {return !between(oilt[1].getValue(),tlo.getValue(),thi.getValue()) and run[0].getValue();},
             1, "    OIL TEMP", eng[1]);
ml.caution(func {return between(oilp[0].getValue(),0,plo.getValue());},
             0, " OIL LOW PRESS", eng[0]);
ml.caution(func {return between(oilp[1].getValue(),0,plo.getValue());},
             1, " OIL LOW PRESS", eng[1]);

ml.warning(func {return between(fu[1].getValue(),0.5,0.85);},
             0, " FUEL RESERVE", "FUEL1");
ml.warning(func {return between(fu[2].getValue(),0.5,0.85);},
             1, " FUEL RESERVE", "FUEL2");

# Warning messages

ml.warning(func {return ( (xfer[0].getValue() == 0 or xfer[1].getValue() == 0)  or (xfer[0].getValue() == 1 or xfer[1].getValue() == 1) and fu[0].getValue() < 0.005); },2, "FWD+AFT FUEL PUMP", "");

ml.warning(func {return between(mgbpress.getValue() , 0, plo.getValue());},
                  2, "MGB LOW PRESS","");
ml.warning(func {return between(fu[1].getValue(),0,0.5);},
             0, "         LOW", "FUEL1");
ml.warning(func {return between(fu[2].getValue(),0,0.5);},
             1, "         LOW", "FUEL2");
ml.warning(func {return between(n1[1].getValue(),-1,50);},
             1, "        FAIL", eng[1]);
ml.warning(func {return between(n1[0].getValue(),-1,50) and !training.getValue();},
             0, "        FAIL", eng[0]);
                  
# main:

var MasterListLoop = func {
  ml.update();
  settimer(MasterListLoop, 0.5);
  }
  
setlistener("/sim/signals/fdm-initialized", func { MasterListLoop(); });
