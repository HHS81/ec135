# mfd.nas to drive gauges of the VMD MFD #

### Original code copied from EC130.nas, original author Melchior Franz ###
### adopted by litzi for Helionix VMD-, NAVD-, DMAP- and FND-displays ###

print("Helionix MFD ...");

var updaters = []; #this is a list containing all objects that need regular update

#helper functions

var max = func(a, b) a > b ? a : b;
var min = func(a, b) a < b ? a : b;
var clamp = func(v, min = 0, max = 1) v < min ? min : v > max ? max : v;
var rem = func(val, div) { return val-int(val/div)*div;}

var isin = func (needle, haystack) {
  var i=0;
  foreach (x; haystack) {
    if (x==needle) return i;
    i += 1;
    }
  return -1;
}

var pad2strings = func(a, b, l) {
    var d = l-size(a)-size(b);
    if (d>0) {
        var spc = left("                    ",d);
        return (a ~ spc ~ b);
    } else {
        return substr(a, d) ~ " " ~ b;
    }
}
    
var toggleprop = func (prop) setprop(prop, getprop(prop) == nil ? 0 : !getprop(prop) );

var cycleprop = func (prop, opts) {
    k = getprop(prop);
    if (k==nil) {
      setprop(prop, opts[0]);
      return;
      }
      
    i = isin(k, opts);
    if (i<0) {
      setprop(prop, opts[0]);
      return;
      }
      
    # cycle to next element in list
    i = rem(i+1, size(opts));
    setprop(prop, opts[i]);
}

# some constants needed for the XML code
props.globals.initNode("/constants/true",1,"BOOL");
props.globals.initNode("/constants/false",0,"BOOL");
props.globals.initNode("/constants/zero",0,"DOUBLE");

# init some configuration parameters for the MFDs
var mfdroot = "/instrumentation/efis/";

var rngprop = mfdroot ~ "navd/range";
var scaleprop = mfdroot ~ "navd/scale";
var numprop = mfdroot ~ "vmd/nums";
var datapageprop = mfdroot ~ "vmd/datapage";
var bear0prop = mfdroot ~ "fnd/bearingsource[0]";
var bear1prop = mfdroot ~ "fnd/bearingsource[1]";
var navsrprop = mfdroot ~ "fnd/navsource";
var mapprop = mfdroot ~ "dmap/terrainmode";
var planprop = mfdroot ~ "dmap/planmode";
var dataprop = mfdroot ~ "dmap/db-mode";
var databpage = mfdroot ~ "dmap/db-page";
var datafltr  = mfdroot ~ "dmap/db-filter";

setprop(rngprop, 5);
setprop(bear0prop, 0);
setprop(bear1prop, 0);
setprop(navsrprop, "FMS"); 
setprop(mapprop, 0); 
setprop(planprop, 1); 
setprop(dataprop, 1); 
setprop(databpage, 0); 
setprop(datafltr, 1); 
setprop(datapageprop, 0); 

### Eucopter MFD panel control class ###

# Bezel Button Numbers
#    2 3 4 5 6 7 
#[1]<pwr           
# 25                8
# 24                9
# 23                10
# 22                11
# 21                12
# 20                13
#  19 18 17 16 15 14

var EUcoptermfd = {
    new: func(i) {
        var m = { parents: [EUcoptermfd] };
        m.id = i;
        m.idx = 0;
        m.pwr_state = 0;
        
        #split the modes list
        m.list = split(",", getprop("/instrumentation/mfd["~i~"]/mode-list"));
        m.l = size(m.list);
        
        m.supply = getprop("instrumentation/mfd["~i~"]/supply");
        m.supply = m.supply == nil ? "systems/electrical/volts" : m.supply;
        
        m.pwr_sw = "instrumentation/mfd["~i~"]/pwr-sw-pos";
        m.mode = "instrumentation/mfd["~i~"]/mode";
        m.volt=15; # mfd voltage demand (just a guess)
        setprop(m.mode, m.list[0] );
        return m;
        },
        
    update: func() {
      var v = getprop(me.supply);
      v = v == nil ? 0 : v;
      
      if (!me.pwr_state and getprop(me.pwr_sw) and v >= me.volt) {
         setprop(me.mode, "INIT");    # show power-on screen for 3 sec
         me.pwr_state=1;
         me.idx=0;
         settimer(func {me.modeprop()}, 3 + 0.2*me.id );
       } else if (!getprop(me.pwr_sw) or v < me.volt) {
         me.pwr_state=0;
         setprop(me.mode, "OFF");   # show blank screen
       }  
      },

    modeprop: func () setprop(me.mode, me.list[me.idx]),

    setmode: func (modestr) {
        i = isin(modestr, me.list); 
        if (i>=0) { me.idx=i; me.modeprop();}
        },

    getmode: func () {
        return getprop(me.mode);
        },
        
    pwr_on: func () {
        setprop(me.pwr_sw, 1);
        },
    
    pwr_off: func () {
        setprop(me.pwr_sw, 0);
        },
    
    clickon: func (n) {
        var mymode = me.getmode();
        if (me.pwr_state) {
          if (n==2) me.setmode("FND");
          if (n==3) me.setmode("NAVD");
          if (n==4) me.setmode("VMD");
          if (n==5) me.setmode("DMAP");
          if (n==9) {
              if (mymode=="DMAP") toggleprop(planprop);
              }
          if (n==10) {
              if (mymode=="NAVD") toggleprop(bear0prop);
              if (mymode=="DMAP") toggleprop(dataprop);
              if (mymode=="VMD") toggleprop(numprop);              
              }
          if (n==11) {
              if (mymode=="FND") toggleprop(bear0prop);
              if (mymode=="NAVD") toggleprop(bear1prop);
              }
          if (n==12) {
              if (mymode=="FND") toggleprop(bear1prop);
              if (mymode=="DMAP") cycleprop(datafltr, [1,3,4] );
              }              
          if (n==13) {
              if (mymode=="DMAP") cycleprop(databpage, [0,1,2]);
              }              
          if (n==16) {
               #if (mymode=="DMAP") cycleprop(databpage, [0,1,2]);
               }
          if (n==19) {
               if (mymode=="NAVD" or mymode=="DMAP") cycleprop("autopilot/afcs/control/nav1-coupled", [1,0]);
                if (mymode=="FND") cycleprop("autopilot/afcs/control/nav1-coupled", [1,0]);
               }
          if (n==20) {
              if (mymode=="FND") cycleprop(navsrprop, ["", "NAV2", "FMS"]);
              }
          if (n==21) {
              if (mymode=="VMD") cycleprop(datapageprop, [0,1,2]);
              }
          if (n==24) {
            if (mymode=="NAVD" or mymode=="DMAP") cycleprop(rngprop, [2, 5, 10, 20]);
            }
          if (n==25) {
              if (mymode=="NAVD") cycleprop(navsrprop, ["", "NAV2", "FMS"]);
              if (mymode=="DMAP") toggleprop(mapprop);
              }
        }
        if (n==1) toggleprop(me.pwr_sw); # toggle power property !!!
     }
};
      
var mfd0 = EUcoptermfd.new(0);
var mfd1 = EUcoptermfd.new(1);
var mfd2 = EUcoptermfd.new(2);
var mfd3 = EUcoptermfd.new(3);
append(updaters, mfd0);
append(updaters, mfd1);
append(updaters, mfd2);
append(updaters, mfd3);

###create fuelflow###
#todo:change this into property rule in filter.xml to reduce nasal overhead

var fuelflow =  func(n){
  var power = props.globals.getValue("/controls/engines/engine[" ~ n ~ "]/power", 0);
  var rpm   = props.globals.getValue("/engines/engine[" ~ n ~ "]/n1-pct") or 0;
  
  #by litzi: expose fuelflow in pound per hour to property tree (150 kg/h @ 100%n1)
  if ( rpm > 0 ) interpolate ("/engines/engine[" ~ n ~ "]/fuel-flow_pph", rpm * 1.5 * KG2LB, 4);
  
  settimer(func { fuelflow(n) }, 1);
}

fuelflow(0);
fuelflow(1);

###create fuel endurance in sec###
#todo:change this into property rule in filter.xml to reduce nasal overhead

var fuelendurance = {
  update: func () {
      qty =   props.globals.getNode("/consumables/fuel/total-fuel-lbs",1);
      ff = [];
      append(ff, props.globals.getNode("/engines/engine[0]/fuel-flow_pph",1));
      append(ff, props.globals.getNode("/engines/engine[1]/fuel-flow_pph",1));
      endu = props.globals.getNode("/consumables/fuel/endurance-sec",1);

      if (ff[0].getValue() and ff[1].getValue()) {
        ffx = ff[0].getValue() + ff[1].getValue(); #pound/h
        
        if (ffx <= 0) {
          endu.setValue(0);
        } else {
          ss=qty.getValue()/ffx*3600;
          interpolate(endu,ss,10);
        }
      } else {
          endu.setValue(0);
      }
    }
};

append(updaters, fuelendurance);

###create oil pressure###

### code copied from EC130.nas, original author Melchior Franz ###

var oilpressure =  func(n){

  oilpres_low = props.globals.getNode("/engines/engine[" ~ n ~ "]/oil-pressure-low", 1);
  oilpres_norm = props.globals.getNode("/engines/engine[" ~ n ~ "]/oil-pressure-norm", 1);
  oilpres_bar = props.globals.getNode("/engines/engine[" ~ n ~ "]/oil-pressure-bar", 1);

  var rpm = props.globals.getValue("/engines/engine[" ~ n ~ "]/n2-rpm") or 0;

  if ( rpm > 0 ) oilpres_low.setDoubleValue((15-22000/rpm)*0.0689);
  if ( rpm > 0 ) oilpres_norm.setDoubleValue((60-22000/rpm)*0.0689);

  settimer(func { oilpressure(n) }, 0);
}

oilpressure(0);
oilpressure(1);

##############

var oilpressurebar = func(n){

  oilpres_bar = props.globals.getNode("/engines/engine[" ~ n ~ "]/oil-pressure-bar", 1);

  var rpm = props.globals.getValue("/engines/engine[" ~ n ~ "]/n2-rpm") or 0;
  var oilpres_low = props.globals.getValue("/engines/engine[" ~ n ~ "]/oil-pressure-low") or 0;
  var oilpres_norm = props.globals.getValue("/engines/engine[" ~ n ~ "]/oil-pressure-norm") or 0;

  # by litzi clamp oilpressure >= 0
  
  if ((rpm > 0) and (rpm < 23000)){
    interpolate ("/engines/engine[" ~ n ~ "]/oil-pressure-bar", max(oilpres_low, 0) , 1.5);
  }elsif (rpm > 23000) {
    interpolate ("/engines/engine[" ~ n ~ "]/oil-pressure-bar", max(oilpres_norm, 0) , 2);
  }

  settimer(func { oilpressurebar(n) }, 0.1);
}

oilpressurebar(0);
oilpressurebar(1);

##################

var oiltemp = func(n){

  var OAT = props.globals.getValue("/environment/temperature-degc") or 0;
  var oilpres_bar = props.globals.getValue("/engines/engine[" ~ n ~ "]/oil-pressure-bar") or 0;
  var rpm = props.globals.getValue("/engines/engine[" ~ n ~ "]/n2-rpm") or 0;
  ot = props.globals.getNode("/engines/engine[" ~ n ~ "]/oil-temperature-degc", 1);

  
  if (oilpres_bar >1){
    interpolate ("/engines/engine[" ~ n ~ "]/oil-temperature-degc", ((25-22000/rpm)*oilpres_bar)+OAT , 20);
  } else {
    interpolate ("/engines/engine[" ~ n ~ "]/oil-temperature-degc", OAT , 20);
  }

  settimer( func { oiltemp(n) }, 0);
}

oiltemp(0);
oiltemp(1);

### code copied from EC130.nas, original author Melchior Franz ###
###main gear box oil pressure###

var mgbp =  func {

  #create oilpressure#
  mgb_oilpres_low = props.globals.getNode("/rotors/gear/mgb-oil-pressure-low", 1);
  mgb_oilpres_norm = props.globals.getNode("/rotors/gear/mgb-oil-pressure-norm", 1);
  mgb_oilpres_bar = props.globals.getNode("/rotors/gear/mgb-oil-pressure-bar", 1);

  var rpm = props.globals.getValue("/rotors/main/rpm") or 0;

  if ( rpm > 0 ) mgb_oilpres_low.setDoubleValue((15-230/rpm)*0.0689);
  if ( rpm > 0 ) mgb_oilpres_norm.setDoubleValue((60-230/rpm)*0.0689);

  settimer(mgbp, 0);
}

mgbp();

##############

var mgbp_bar = func{

  mgb_oilpres_bar = props.globals.getNode("/rotors/gear/mgb-oil-pressure-bar", 1);

  var rpm = props.globals.getValue("/rotors/main/rpm") or 0;
  mgb_oilpres_low = props.globals.getValue("/rotors/gear/mgb-oil-pressure-low") or 0;
  mgb_oilpres_norm = props.globals.getValue("/rotors/gear/mgb-oil-pressure-norm") or 0;

  if ((rpm > 0) and (rpm < 280)){
    interpolate ("/rotors/gear/mgb-oil-pressure-bar",max(mgb_oilpres_low,0), 1.5);
  }elsif (rpm > 280) {
    interpolate ("/rotors/gear/mgb-oil-pressure-bar",max(mgb_oilpres_norm,0), 2);
  }

  settimer(mgbp_bar, 0.1);
}

mgbp_bar();


####Calculation into "FLI"###

## First Limit Indicator - FLI
## Originally adopted from ec130 VEMD.nas .
## However the ec135/ec130, VEMD FLI indication differs 
## from the H145 Helionix FND FLI tape:
## according to Neuhaus/Ockier - "Helionix Cockpit Concept" the 
## "FLI scale uses the collective lever position" 
## to display the "moving collective pitch scale".
## The moving markers on top of the FLI tape indicate at which 
## collective pitch the reaching of MCP, take-off- and transient-TO
## torque limits are expected.

var fli = {

  # define objects constants
  flimcp : 6.9,  # max. continuous 69% TRQ
  flitop : 7.8,  # take off power 78% TRQ for max. 5 mins
  flisync : 0.1,
  flittop :10.4, # transient take off power 104% TRQ for max. 10 sec.
  trqf :  aircraft.lowpass.new(5), # slowly adapt the torque factor
  trqfac : 0,
  offset : 0,


init: func {
      #set the calibration paramters
      if (!getprop("instrumentation/efis/fnd/fli-mcp-cal")) {
          setprop("instrumentation/efis/fnd/fli-mcp-cal",0.5);
          setprop("instrumentation/efis/fnd/fli-top-cal",0.3);
          setprop("instrumentation/efis/fnd/fli-ttop-cal",0.35);
          setprop("instrumentation/efis/fnd/fli-sync-cal",1);        
      }
      me.trqf.set(2.0); 
      },

update: func {
      # for FLI all params normalized to 10     
      var coll = getprop("/controls/engines/engine/throttle");
      var trq = max( getprop("/engines/engine/torque-pct") or 0,
                getprop("/engines/engine[1]/torque-pct") or 0)/10;
      
      # FLI tape follows the collective pitch
      var flitape = (1.0 - coll) * 10.0; 
      if (flitape>1 and trq>1) me.trqf.filter(flitape/trq);
      # normalize to TRQ at medium TOW 2900 at 60kt (~2 --> 0)
      me.trqfac = clamp(me.trqf.get()-2, -1, 1);
      
      setprop("instrumentation/efis/fnd/fli-tape", flitape);
      
      # FLI marker positions relative to reference line:
     setprop("instrumentation/efis/fnd/fli-mcp", 
           (me.flimcp - trq)* me.trqf.get() *
           getprop("instrumentation/efis/fnd/fli-mcp-cal"));
           
      setprop("instrumentation/efis/fnd/fli-top", 
          (me.flitop - trq)* me.trqf.get() *
          getprop("instrumentation/efis/fnd/fli-top-cal"));
           
      setprop("instrumentation/efis/fnd/fli-ttop", 
          (me.flittop - trq)* me.trqf.get() *
          getprop("instrumentation/efis/fnd/fli-ttop-cal"));
      
      setprop("instrumentation/efis/fnd/fli-sync",
          (me.flisync - trq)* me.trqf.get() *
          getprop("instrumentation/efis/fnd/fli-sync-cal"));
  }
};
      
fli.init();      
append(updaters, fli);

# ==== NAVDISPLAY =====
# calculate bearing and distances of navaids for navdisplay (navd).
# the last and the next 4 waypoints of the flightplan are 
# shown on the navd.

var navdisplay = {
  init: func () {
    #var m = { parents: [navdisplay] };
    #return m;
    me.maxrng = 40;
    me.maxn = 20;
    me.navlist = [];
    me.usedids = std.Vector.new();
    me.navdfilter = 1;
    me.rr = 5;
  },

  addsym: func (i, x) {
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/sym",
            x.symbol);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/distance-norm",
            x.reldst);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/distance-nm",
            x.distance_nm);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/rel-bearing",
            x.relbearing);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/bearing-deg",
            x.bearing_deg);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/rel-course",
            x.relcourse);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/id", x.id);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/ils-course", x.course);
    
    var info = "";
    # generate the info string for VOR and ILS
    if (x.symbol == 0 or x.symbol == 5)
         var info = sprintf("%-8.8s %6.2f", x.name, x.frequency/100);
    #..for waypoints     
    if (x.symbol == 1 or x.symbol == 4) var info=sprintf("%-11.11s", x.name);
    
    if (x.symbol == 2)        
         var info = sprintf("%-11.11s %3.0f", x.name, x.frequency/100);
    if (x.symbol == 3)
         var info = sprintf("%-8.8s %4.0fft", x.name, x.elevation*M2FT);
    
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/info", info);
    
    if (x.type == "ILS" or x.type == "VOR" or x.type == "NDB")
        setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/frequency", x.frequency);
    else
        setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/frequency", 0);
    
    return x.id;
  },

  delsym: func (i) {
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/sym", -1);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/distance-norm", 99);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/distance-nm", "");
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/rel-bearing", 0);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/rel-course", 0);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/bearing-deg", "");
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/ils-course", 0);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/frequency", 0);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/id", "");
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/info", "");
  },

  update: func() {

    me.navlist = [];
    me.usedids = std.Vector.new();
    me.navdfilter = getprop(datafltr);
    me.rr = (getprop(rngprop) or 1) * (getprop(scaleprop) or 1);

    if (me.navdfilter==1 or me.navdfilter==2 or me.navdfilter==4) {
      
        # add flightplan waypoints on top of list
        var fplan = flightplan();
        var fplans = fplan.getPlanSize();
        # for mode 1 show only 4 next wypts
        
        var first = max(0, fplan.current - 1);
        var n = (me.navdfilter!=1) ? fplans : min(5 + first, fplans);
        
        for (var i=first; i<n; i+=1) {
            var thiswp = fplan.getWP(i);
            me.addto([thiswp],(i == fplan.current) ? 4 : 1);
            me.usedids.append(thiswp.id);
            }
        }
        
    if (me.navdfilter==1) {
        var x=findNavaidsWithinRange(me.maxrng, "airport");
        me.addto(x,3);
        }
        
    if (me.navdfilter==1 or me.navdfilter==3) {
        var x=findNavaidsWithinRange(me.maxrng, "vor");
        me.addto(x,0);
        }
        
    if (me.navdfilter==1 or me.navdfilter==3) {
        var x=findNavaidsWithinRange(me.maxrng, "ndb");
        me.addto(x,2);
        }
        
    if (me.navdfilter==3) {
        var x=findNavaidsWithinRange(me.maxrng, "ils");
        me.addto(x,5);
        }
        
    if (me.navdfilter==2) {
        var x=findNavaidsWithinRange(me.maxrng, "fix");
        me.addto(x,6);
        }
        
    # sort all the symbols by distance from aircraft
    # except in flightplan views
    
    if (me.navdfilter!=4) 
        me.navlist = sortNavaidByDistance(me.navlist);
    
    l = min(me.maxn, size(me.navlist));
    
    # then transfer up to maxn to the plan view properties
    for (var j=0; j < l; j+=1) me.addsym(j, me.navlist[j] );
        
    # deactivate unused symbols
    if (j <= me.maxn) for (var i = j; i < me.maxn; i+=1) me.delsym(i);
  
  },
   
  addto: func(x, symbol) {
          var myhdg = getprop("/orientation/heading-deg");
          
          foreach(var sym; x) {
           if (!me.usedids.contains(sym.id)) {
              var y = ghostcopy(sym);
              
              var (c, d) = courseAndDistance(
                      {lat: sym.lat, 
                       lon: sym.lon} );
                       
              y.distance_nm = d;
              y.bearing_deg = c;
              y.symbol = symbol;
              y.relbearing  = c - myhdg;
              y.relcourse  = y.course - myhdg;
              y.reldst = d / me.rr;
              
              append(me.navlist, y);
           }
          }
   }

};

navdisplay.init();
append(updaters, navdisplay);

var ghostcopy = func (gin) {
  out = {};
  out.id = gin.id;
  
  if (ghosttype(gin) != "flightplan-leg") {
      out.type = gin.type;
      out.name = gin.name;
      out.elevation = gin.elevation or 0;
      out.frequency = gin.frequency or 0;
      out.course = gin.course or 0;
  } else {
      out.type = "FIX";
      out.name = "";
      out.elevation = 0;
      out.frequency = 0;
      out.course = 0;
  }    
  return out;
}

sortNavaidByDistance = func (listofnav) {
   #return the sorted list
   return sort(listofnav, 
         func (a,b) {return a.distance_nm > b.distance_nm ? 1 : -1}
         );
}

# === UPDATERS ===
var mfdupdateloop = func () {
  foreach(x; updaters) { x.update() }
  # call timer for next update loop 
  settimer(mfdupdateloop, 0.1);
}  

setlistener("sim/signals/fdm-initialized", mfdupdateloop );

print(" Initialized");