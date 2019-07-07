# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

# those two need to be in the global scope
var fnd_canvas = nil;
var fnd_display = nil;

var _list = setlistener("sim/signals/fdm-initialized", func() {
        fnd_display = canvas.new({
                "name": "FND",
                "size": [1024, 1024],
                "view": [1050, 1000],
                "mipmapping": 1
        });
        
        fnd_display.addPlacement({"node": "helionix0"});
        
        var group = fnd_display.createGroup();
        fnd_canvas = canvas_MFD.new(group, helionixpath ~ "svg/fnd.svg");
        
        var ROSESC = 0.58;
        var ROSEX = 180;
        var ROSEY = ROSEX * ROSESC;
        var DMEFACTOR = 0.0005399;
        var ALTFACTOR = (651-464)/400;  
        var FPS2FPM = 60;
        
        var SHIFT_THRES = 0.5;
        var ROT_THRES = 0.1;
              
        var ralt_lut = LUT.new([[0,0], [100,123.8], [1000,678.5], [2200,1173.5], [2500,1500]]);

        
        # add sensor elements. to avoid repeated readout of the same 
        # property values we define sensors (originally seen in Thorstens Zivko Edge)
        # =========================
        
        # properties that change very frequently will be polled to avoid overhead (disable_listener)
        
        var roll = Sensor.new({"prop":"orientation/roll-deg", "disable_listener": FAST, "thres":0.1 });
        var pitch = Sensor.new({"prop": "orientation/pitch-deg", "disable_listener": FAST, "thres":0.1});
        var ias = Sensor.new({"prop": "instrumentation/airspeed-indicator/indicated-speed-kt", "disable_listener":FAST, "thres":0.1});
        var alt = Sensor.new({"prop": "instrumentation/altimeter/indicated-altitude-ft", "disable_listener":FAST, "thres":0.5});
        var vs = Sensor.new({"prop": "velocities/vertical-speed-fps", "disable_listener":FAST, "thres":0.1});
        var agl = Sensor.new({"prop": "position/altitude-agl-ft", "disable_listener":FAST, "thres":0.1});
        var agllut = Sensor.new({"function": func {return ralt_lut.get(agl.get())}, "thres": 0.01});
        
        var heading = Sensor.new({"prop": "orientation/heading-magnetic-deg", "disable_listener":FAST, "thres":0.1});
        
        var nr = Sensor.new({"prop": "rotors/main/rpm-pct", "thres":0.1});
        var n2_1 = Sensor.new({"prop": "engines/engine[0]/n2-pct", "thres":0.1});
        var n2_2 = Sensor.new({"prop": "engines/engine[1]/n2-pct", "thres":0.1});
        
        var nav0dmeinrange = Sensor.new({"prop": "instrumentation/nav[0]/dme-in-range"});
        var nav1dmeinrange = Sensor.new({"prop": "instrumentation/nav[1]/dme-in-range"});
        var nav0inrange = Sensor.new({"prop": "instrumentation/nav[0]/in-range"});
        var nav1inrange = Sensor.new({"prop": "instrumentation/nav[1]/in-range"});
        var adf0inrange = Sensor.new({"prop":"instrumentation/adf[0]/in-range"});
        var nav0hasgs = Sensor.new({"prop": "instrumentation/nav[0]/has-gs"});
        var nav1hasgs = Sensor.new({"prop": "instrumentation/nav[1]/has-gs"});
        var nav0gsinrange = Sensor.new({"prop": "instrumentation/nav[0]/gs-in-range"});
        
        var nav0crs = Sensor.new({"prop": "instrumentation/nav[0]/radials/selected-deg" });
        var qnh = Sensor.new({"prop": "instrumentation/altimeter/setting-inhg"});
        var fli = Sensor.new({"prop": "instrumentation/efis/fnd/fli-tape"});
        var slipskid = Sensor.new({"prop": "instrumentation/slip-skid-ball/indicated-slip-skid"});
        var nav1bear = Sensor.new({"prop": "instrumentation/nav[1]/rel-bearing-deg"}); 
        var adf0bear = Sensor.new({"prop": "instrumentation/adf[0]/indicated-bearing-deg"});
        var headbug = Sensor.new({"prop": "autopilot/settings/heading-bug-deg"});
        var nav0defl = Sensor.new({"prop": "instrumentation/nav[0]/heading-needle-deflection"});
        
        var aproll = Sensor.new({"prop": "autopilot/locks/heading", "text":1 });
        var apalt = Sensor.new({"prop": "autopilot/locks/altitude", "text":1 });
        var aprollarm = Sensor.new({"prop": "autopilot/locks/heading-arm", "text":1});
        var apaltarm = Sensor.new({"prop": "autopilot/locks/altitude-arm", "text":1});
        
        var apspeed = Sensor.new({"prop": "autopilot/locks/speed", "text":1});
        var apcoll = Sensor.new({"prop": "autopilot/internal/use-collective-for-alt"});
        
        # define some helper functions
        # ============================
        
        var rose_mark_x = func (w) math.sin((w*10 - heading.get())*D2R)*ROSEX;
        var rose_mark_y = func (w) -math.cos((w*10 - heading.get())*D2R)*ROSEY;
        var DME_format = func (p) { x = (getprop(p) or 0) * DMEFACTOR; return sprintf((x>10) ? "%3.0f NM" : "%4.1f NM", x); }; 
      
        var rose_mark_x = func (w) math.sin((w*10 - heading.get())*D2R)*ROSEX;
      
        var altTs = func (n) {
            var a = (alt.get() or 0) + n*100;
            var x = int(a/1000);
            if (a<0 and x==0) return "-0";
            return ""~x;
            };
            
        var altHs = func (n) {
          var a = (alt.get() or 0) + n*100;
          var x = abs( math.floor(math.fmod(a,1000)/100) );
          if (x==0) return "000";
          if (x==5) return "500";
          return "" ~ x;
        };

        var altShift = func {
          var a=alt.get();    
          return ALTFACTOR * ( (a>0) ? math.fmod(a,100) : (100 + math.fmod(a,100)) ); 
        };
        
        var altMove = func (n) {
          var a=alt.get() + n*100;    
          var x = int(a/1000);
          
          if (a<0 and x==0) return 7;
          return (x < 0 or x > 9) ? 12 : 1; 
        };
                
        
             
        
        # generate the alt tape labels' svg ids
        # ============================
        
        var altnumgrpT = [];
        for (var n=-4;  n<6; n+=1) append(altnumgrpT, "altNum" ~ n);
        
        var altnumgrpH = [];
        for (var n=-4; n<6; n+=1) append(altnumgrpH, "Hnum" ~ n);
        
        # note: optional named arguments did not work,
        # therefore a hash is used as argument to add_trans()
        
        # alt tape elements animation
        # move the thousand and hundret numerals, use "fast" option for labels
        # ============================
               
        #fnd_canvas.add_trans("alttape", "y-shift", {"function": func altShift(), "delta": 0.1 });
        #fnd_canvas.add_trans_grp(altnumgrpT, "y-shift", {"function": func altShift(), "delta": SHIFT_THRES });
        #fnd_canvas.add_trans_grp(altnumgrpH, "y-shift", {"function": func altShift(), "delta": SHIFT_THRES });

        fnd_canvas.add_trans_grp(["radarAlttape", "aglBug"], "y-shift",  {"sensor": agllut });
        fnd_canvas.add_trans("aglBug", "y-shift", {"function": func {return -ralt_lut.get( getprop("/autopilot/settings/target-agl-ft") );} });
      
        fnd_canvas.add_trans("alttape", "y-shift", {"sensor":alt, "scale": ALTFACTOR, "mod":100});
        fnd_canvas.add_trans("altBug", "y-shift", {"sensor":alt, "scale": ALTFACTOR});
        fnd_canvas.add_trans("altBug", "y-shift", {"sensor": Sensor.new({"prop": "/autopilot/settings/target-altitude-ft"}) , "scale": -ALTFACTOR});
        
        fnd_canvas.add_trans_grp(altnumgrpT, "y-shift", {"sensor":alt, "scale": ALTFACTOR, "mod":100} );
        fnd_canvas.add_trans_grp(altnumgrpH, "y-shift", {"sensor":alt, "scale": ALTFACTOR, "mod":100} );
        
        fnd_canvas.add_text( "altNum-4", { "function": func altTs(-4)});        
        fnd_canvas.add_text( "altNum-3", { "function": func altTs(-3)});
        fnd_canvas.add_text( "altNum-2", { "function": func altTs(-2)});        
        fnd_canvas.add_text( "altNum-1", { "function": func altTs(-1)});        
        fnd_canvas.add_text( "altNum0", { "function": func altTs(0)});        
        fnd_canvas.add_text( "altNum1", { "function": func altTs(1)});
        fnd_canvas.add_text( "altNum2", { "function": func altTs(2)});
        fnd_canvas.add_text( "altNum3", { "function": func altTs(3)});
        fnd_canvas.add_text( "altNum4", { "function": func altTs(4)});
        fnd_canvas.add_text( "altNum5", { "function": func altTs(5)});
        
        fnd_canvas.add_text( "Hnum-4", { "function": func altHs(-4)});        
        fnd_canvas.add_text( "Hnum-3", { "function": func altHs(-3)});        
        fnd_canvas.add_text( "Hnum-2", { "function": func altHs(-2)});        
        fnd_canvas.add_text( "Hnum-1", { "function": func altHs(-1)});        
        fnd_canvas.add_text( "Hnum0", { "function": func altHs(0)});        
        fnd_canvas.add_text( "Hnum1", { "function": func altHs(1)});
        fnd_canvas.add_text( "Hnum2", { "function": func altHs(2)});
        fnd_canvas.add_text( "Hnum3", { "function": func altHs(3)});
        fnd_canvas.add_text( "Hnum4", { "function": func altHs(4)});
        fnd_canvas.add_text( "Hnum5", { "function": func altHs(5)});
        
        # make room to the left of the two-digit wide alt labels
        # ============================
        
        fnd_canvas.add_trans( "Hnum-4", "x-shift", {"function": func altMove(-4), "delta": SHIFT_THRES});
        fnd_canvas.add_trans( "Hnum-3", "x-shift", {"function": func altMove(-3), "delta": SHIFT_THRES});
        fnd_canvas.add_trans( "Hnum-2", "x-shift", {"function": func altMove(-2), "delta": SHIFT_THRES});
        fnd_canvas.add_trans( "Hnum-1", "x-shift", {"function": func altMove(-1), "delta": SHIFT_THRES});
        fnd_canvas.add_trans( "Hnum0", "x-shift", {"function": func altMove(0), "delta": SHIFT_THRES});
        fnd_canvas.add_trans( "Hnum1", "x-shift", {"function": func altMove(1), "delta": SHIFT_THRES});
        fnd_canvas.add_trans( "Hnum2", "x-shift", {"function": func altMove(2), "delta": SHIFT_THRES});
        fnd_canvas.add_trans( "Hnum3", "x-shift", {"function": func altMove(3), "delta": SHIFT_THRES});
        fnd_canvas.add_trans( "Hnum4", "x-shift", {"function": func altMove(4), "delta": SHIFT_THRES});
        fnd_canvas.add_trans( "Hnum5", "x-shift", {"function": func altMove(5), "delta": SHIFT_THRES});

        fnd_canvas.add_trans("altBack", "y-shift", {"sensor": agl, "scale": 130/280 , "max":280, "min":-280 });
        
        
        # move speed and fli tapes, animate ai elements
        # ============================
        
        fnd_canvas.add_trans("speedtape", "y-shift", {"sensor": ias, "scale": 3.19, "max": 350 });
        fnd_canvas.add_trans("iasBug", "y-shift", {"sensor": ias, "scale": 3.19 });
        fnd_canvas.add_trans("iasBug", "y-shift", {"sensor": Sensor.new({"prop": "/autopilot/settings/target-speed-kt"}), "scale": -3.19 });
        
        
        fnd_canvas.add_trans("flitape", "y-shift", {"sensor": fli, "scale": 90.3, "offset": 0, "max": 10, "min": 0 });
        fnd_canvas.add_trans("fli_sync", "y-shift", {"sensor": Sensor.new({"prop":  "instrumentation/efis/fnd/fli-sync"}), "scale": -90.3, "offset": 0, "max": 10, "min": -10, "delta": SHIFT_THRES });
        fnd_canvas.add_trans("fli_ttop", "y-shift", {"sensor": Sensor.new({"prop":  "instrumentation/efis/fnd/fli-ttop"}), "scale": -90.3, "offset": 0, "max": 10, "min": -10, "delta": SHIFT_THRES });
        fnd_canvas.add_trans("fli_mcp", "y-scale", {"function": func {return getprop("instrumentation/efis/fnd/fli-top") - getprop("instrumentation/efis/fnd/fli-mcp");}  });
        fnd_canvas.add_trans("fli_mcp", "y-shift", {"sensor": Sensor.new({"prop":  "instrumentation/efis/fnd/fli-mcp"}), "scale": -90.3, "offset": 0, "max": 10, "min": -10, "delta": SHIFT_THRES });

        fnd_canvas.add_trans("horizon", "y-shift", {"sensor": pitch, "scale": 3.6, "max": 90 , "min":-90});
        fnd_canvas.add_trans("horizon", "rotation", {"sensor": roll, "scale": -1});

        fnd_canvas.add_trans("horizonNums", "y-shift", {"sensor": pitch, "scale": 3.6, "max": 90 , "min":-90});
        fnd_canvas.add_trans("horizonNums", "rotation", {"sensor": roll, "scale": -1});
        fnd_canvas["horizonNums"].set("clip", "rect(150, 400, 330, 150)"); # clip: top, right, bottom, left
        
        fnd_canvas.add_trans("rollPointer", "rotation", {"sensor": roll, "scale": -1 });
        fnd_canvas.add_trans("slipSkid", "x-shift", {"sensor" : slipskid, "scale": -25 });
        
        fnd_canvas.add_text("aglNum", {"sensor": agl, "format": "%3.0f", "offset":-5.22, "trunc": "abs"});
        fnd_canvas.add_cond("aglNum", {"function": func { (agl.get()<1000) ? 1 : 0}});
        
        # move vsi needle and numerical indication
        # ============================
        
        fnd_canvas.add_trans("vsi", "rotation", {"sensor": vs, "scale":-1.2, "max":35, "min":-35});
        fnd_canvas.add_trans_grp(["vsi", "vsiNum"], "y-shift", {"sensor": vs, "scale": -84/2000*FPS2FPM, "max":35, "min":-35 });
        fnd_canvas.add_trans("vsBug", "y-shift", {"sensor": Sensor.new({"prop": "autopilot/internal/target-climb-rate-fps"}), "scale": -84/2000*FPS2FPM, "max":35, "min":-35 });
        fnd_canvas.add_text("vsiNum", {"sensor": vs, "trunc": "abs", "scale": FPS2FPM/100, "format": "%2.0f" });
        fnd_canvas.add_trans("vsiNum", "y-shift", {"function": func { (vs.get() > 0) ? -35 : 0 ;} });
        fnd_canvas.add_cond("vsiNum", {"function": func { (abs(vs.get()) > 3) ? 1 : 0}});
        
        # Rose transformations
        # Bearing Needles
        # ============================
        
        fnd_canvas.add_trans("bear1Needle", "rotation", {"sensor": nav1bear});
        fnd_canvas.add_cond("bear1Needle", {"sensor": nav1inrange});
        
        fnd_canvas.add_trans("bear2Needle", "rotation", {"sensor": adf0bear});
        fnd_canvas.add_cond("bear2Needle", {"sensor": adf0inrange });
        
        
        # course and CDI 
        # ============================
        
        fnd_canvas.add_trans("hdgBug", "rotation", {"sensor": headbug});
        fnd_canvas.add_trans("cdiNeedle", "x-shift", {"sensor": nav0defl, "scale": 8});
        fnd_canvas.add_cond_grp(["cdiNeedle", "toFrom"], {"sensor": nav0inrange});
        
        fnd_canvas.add_trans_grp(["rose", "cdiScale", "toFrom", "crsNeedle", "cdiNeedle", "hdgBug"], "rotation", {"sensor": heading, "scale": -1});
        fnd_canvas.add_trans("toFrom", "rotation", {"sensor": Sensor.new({"prop": "instrumentation/nav[0]/from-flag"}), "scale": 180}); 
                             
        fnd_canvas.add_trans_grp(["cdiScale", "crsNeedle", "cdiNeedle", "toFrom"], "rotation", {"sensor": nav0crs});
        fnd_canvas.add_trans_grp(["rose", "bear1Needle", "bear2Needle", "cdiScale", "cdiNeedle", "crsNeedle", "hdgBug", "toFrom"], "y-scale", {"offset": ROSESC});
        
        fnd_canvas.add_trans("gsNeedle", "y-shift", {"sensor": Sensor.new({"prop": "instrumentation/nav[0]/gs-needle-deflection-norm"}), "scale": -65, "delta": SHIFT_THRES});
        fnd_canvas.add_cond_grp(["gsNeedle", "gsScale"], {"sensor": nav0gsinrange}); 
        
        fnd_canvas.add_trans("speedTrend", "y-scale", {"sensor": Sensor.new({"prop": "velocities/airspeed-delta-kt-sec"}), "scale": 0.02, "max": 40, "min":-40});
        
        
        # lots of text
        # for nav aids to update
        # ============================
        
        fnd_canvas.add_text("bearingFrq1", {"sensor": Sensor.new({"prop": "instrumentation/nav[1]/frequencies/selected-mhz"}), "format": "%6.2f" });
        fnd_canvas.add_text("bearingFrq2", {"sensor": Sensor.new({"prop": "instrumentation/adf[0]/frequencies/selected-khz"}), "format": "%6.2f" });
        fnd_canvas.add_text("navFrq", {"sensor": Sensor.new({"prop": "instrumentation/nav[0]/frequencies/selected-mhz"}), "format": "%6.2f" });
        fnd_canvas.add_text("navID", {"sensor": Sensor.new({"prop": "instrumentation/nav[0]/nav-id", "text":1}) });
        fnd_canvas.add_text("navSrc", {"function": func return nav0hasgs.get() ? "ILS1" : "VOR1", "disable_listener": SLOW });
        fnd_canvas.add_text("bearingSrc1", {"function": func return nav1hasgs.get() ? "ILS2" : "VOR2", "disable_listener": SLOW });
        fnd_canvas.add_text("crs", {"sensor": nav0crs, "format": "%3.0f" });

        fnd_canvas.add_text("navDME", {"function": func DME_format("instrumentation/nav[0]/nav-distance") , "disable_listener": SLOW });
        fnd_canvas.add_text("bearingDME1", {"function": func DME_format("instrumentation/nav[1]/nav-distance"), "disable_listener": SLOW });

        fnd_canvas.add_cond("navDME", {"function": func return nav0dmeinrange.get() and nav0inrange.get(), "disable_listener": SLOW});
        fnd_canvas.add_cond("bearingDME1", {"function": func return nav1dmeinrange.get() and nav1inrange.get(), "disable_listener": SLOW });
        # /instrumentation/nav[0]/has-gs  --> navSrc VOR1/ILS1
        fnd_canvas.add_cond("navETE", {offset:0}); # hide ETE
        

        # fuel indicators 
        # and rotor and eng rmp
        # ============================
        
        fnd_canvas.add_trans("fuelTotal", "y-scale", {"sensor": Sensor.new({"prop": "consumables/fuel/tank[0]/level-norm", "disable_listener": SLOW}) });
        fnd_canvas.add_trans("fuelL", "y-scale", {"sensor": Sensor.new({"prop": "consumables/fuel/tank[1]/level-norm", "disable_listener": SLOW}) });
        fnd_canvas.add_trans("fuelR", "y-scale", {"sensor": Sensor.new({"prop": "consumables/fuel/tank[2]/level-norm", "disable_listener": SLOW}) });
        fnd_canvas.add_text("fuelNum", {"sensor": Sensor.new({"prop":  "consumables/fuel/total-fuel-lbs", "disable_listener": SLOW}), "scale": LB2KG, "format": "%3.0f Kg" });
        fnd_canvas.add_text("nrNum", {"sensor": nr, "format": "%3.0f"});
        fnd_canvas.add_trans_grp(["nrNeedle1", "nrNeedle2"], "rotation", {"sensor": nr, "min": 80 , "max":120, "scale": 180/40, "offset": -360});
        fnd_canvas.add_trans("n2_1Needle", "rotation", {"sensor": n2_1, "min": 80 , "max":120, "scale": 180/40, "offset": -360});
        fnd_canvas.add_trans("n2_2Needle", "rotation", {"sensor": n2_2, "min": 80 , "max":120, "scale": 180/40, "offset": -360});
        fnd_canvas["nrNeedle1"].set("clip", "rect(20, 170, 110, 0)"); # clip: top, right, bottom, left
        
        # note: this works also 
        # fnd_canvas.add_text("fuelNum", {"function":  func sprintf("%3.0fkg", getprop("consumables/fuel/tank[0]/level-norm")*500)  });
        
        fnd_canvas.add_text("OAT", {"sensor": Sensor.new({"prop":  "environment/temperature-degc", "disable_listener": SLOW }), "format": "%3.0f°C" });
        fnd_canvas.add_text("qnh", {"function": func return (qnh.get() == 29.92) ? "STD" : sprintf("%4.0f", qnh.get()*33.8639), "disable_listener": SLOW });


        # AP annunciators text items
        # 
        # ============================

       
        fnd_canvas.add_text("altTarget", {"sensor": Sensor.new({"prop":  "/autopilot/settings/target-altitude-ft"}), "format": "%5.0f"});        
        fnd_canvas.add_cond_grp(["altTarget", "altBug"], {"function": func {return ( apalt.get() == "altitude-hold" or apaltarm.get() == "altitude-hold");} } );
        
        fnd_canvas.add_text("aglTarget", {"sensor": Sensor.new({"prop":  "/autopilot/settings/target-agl-ft"}), "format": "%3.0f"});
        fnd_canvas.add_cond_grp(["aglTarget", "aglBug"], {"function": func {return ( apalt.get() == "agl-hold" or apaltarm.get() == "agl-hold");} } );
        
        fnd_canvas.add_cond("iasBug", {"function": func {return ( apspeed.get() == "speed-with-pitch-trim" );}, "disable_listener": SLOW  } );     
        fnd_canvas.add_cond("vsBug", {"function": func {return ( apalt.get() == "vertical-speed-hold" or apalt.get() == "altitude-hold");}, "disable_listener": SLOW } );

        fnd_canvas.add_text("apLockRoll", {"function": func {                                            
             var r = aproll.get();             
             if (r == "wing-leveler") return "SAS";
             elsif (r == "dg-heading-hold") return "HDG";
             elsif (r == "nav1-hold") return "VOR1";
             elsif (r == "nav2-hold") return "VOR2";
             else return "";           
             }, "disable_listener": SLOW           
        });
        
        fnd_canvas.add_text("apArmRoll", {"function": func {
             var r = aprollarm.get();
             
             if (r == "nav1-hold") return "VOR1";
             elsif (r == "nav2-hold") return "VOR2";
             else return "";           
             }, "disable_listener": SLOW                                     
        });
        
        fnd_canvas.add_text("apLockPitch", {"function": func {
             var a = apalt.get();
             var s = apspeed.get();
             var c = apcoll.get();
             
             if (a == "pitch-hold") return "SAS";
             elsif (a == "altitude-hold" and !c) return "ALT";
             elsif (a == "agl-hold" and !c) return "CR.HT";
             elsif (a == "vertical-speed-hold" and !c) return "V/S";
             elsif (s == "speed-with-pitch-trim") return "IAS";           
             elsif (a == "gs1-hold" and !c) return "G/S1";
             elsif (s == "go-around") return "GA";           
             else return "";           
             }, "disable_listener": SLOW         
        });

        fnd_canvas.add_text("apArmPitch", {"function": func {
             var a = apaltarm.get();
             var c = apcoll.get();
             
             if (a == "altitude-hold" and !c) return "ALT.A";
             elsif (a == "gs1-hold" and !c) return "G/S1";
             else return "";           
             }, "disable_listener": SLOW
        });

        fnd_canvas.add_text("apLockColl", {"function": func {
             var a = apalt.get();
             var c = apcoll.get();
             
             if (a == "altitude-hold" and c) return "ALT";
             elsif (a == "agl-hold" and c) return "CR.HT";
             elsif (a == "go-around") return "GA";
             elsif (a == "vertical-speed-hold" and c) return "V/S";
             elsif (a == "gs1-hold" and c) return "G/S1";
             elsif (a == "fpa-hold" and c) return "FPA";
             else return "";           
             }, "disable_listener": SLOW
        });
        
        fnd_canvas.add_text("apArmColl", {"function": func {
             var a = apaltarm.get();
             var c = apcoll.get();
             
             if (a == "altitude-hold" and c) return "ALT.A";
             elsif (a == "gs1-hold" and c) return "G/S1";
             elsif (a == "agl-hold" and c) return "CR.HT";
             else return "";
             }, "disable_listener": SLOW
        });
        
        # master line text items
        # 
        # ============================
        
        for (var li=0; li<7; li+=1) {
          foreach (var j; [0,1,2])
            fnd_canvas.add_text("ml_"~li~"_"~j, {"prop" : "instrumentation/efis/fnd/masterlist["~li~"]/msg["~j~"]"});
        }
        
        # translate rose numerals in elliptic orbit
        # around center of compass rose
        # ============================

        fnd_canvas.add_trans("markN","y-shift",{"function": func rose_mark_y(0), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("markE","y-shift",{"function": func rose_mark_y(9), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("markS","y-shift",{"function": func rose_mark_y(18), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("markW","y-shift",{"function": func rose_mark_y(27), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark03","y-shift",{"function": func rose_mark_y(3), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark06","y-shift",{"function": func rose_mark_y(6), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark12","y-shift",{"function": func rose_mark_y(12), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark15","y-shift",{"function": func rose_mark_y(15), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark21","y-shift",{"function": func rose_mark_y(21), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark24","y-shift",{"function": func rose_mark_y(24), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark30","y-shift",{"function": func rose_mark_y(30), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark33","y-shift",{"function": func rose_mark_y(33), "delta": SHIFT_THRES});

        fnd_canvas.add_trans("markN","x-shift",{"function": func rose_mark_x(0), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("markE","x-shift",{"function": func rose_mark_x(9), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("markS","x-shift",{"function": func rose_mark_x(18), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("markW","x-shift",{"function": func rose_mark_x(27), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark03","x-shift",{"function": func rose_mark_x(3), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark06","x-shift",{"function": func rose_mark_x(6), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark12","x-shift",{"function": func rose_mark_x(12), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark15","x-shift",{"function": func rose_mark_x(15), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark21","x-shift",{"function": func rose_mark_x(21), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark24","x-shift",{"function": func rose_mark_x(24), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark30","x-shift",{"function": func rose_mark_x(30), "delta": SHIFT_THRES});
        fnd_canvas.add_trans("mark33","x-shift",{"function": func rose_mark_x(33), "delta": SHIFT_THRES});

        fnd_canvas.newMFD();
        removelistener(_list); # run ONCE
});

#setlistener("sim/signals/reinit", func fnd_display.del());

var showPfd = func() {
        var dlg = canvas.Window.new([500, 500], "dialog").set("resize", 1);
        dlg.setCanvas(fnd_display);
}