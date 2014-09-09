#searchlight based on Melchiors shadow on the bo105 and the landinglight Noratlas by Gerad Robin and the extended landinglight PA24-250

var init_actions = func {
   
    setprop("/sim/models/materials/LandingLight/factor-L", 0.0);
    setprop("/sim/models/materials/LandingLight/factor-R", 0.0);
 

    # Request that the update fuction be called next frame
    settimer(update_actions, 0);
}

##
#  Simulate landing light ground illumination fall-off with increased agl distance
##
    var factorL = getprop("/sim/models/materials/LandingLight/factor-L");
    var factorR = getprop("/sim/models/materials/LandingLight/factor-R");
    var agl = getprop("position/altitude-agl-ft");
    var aglFactor = 16/(agl*agl);
    var factorAGL_L = factorL;
    var factorAGL_R = factorR;
    if (agl > 4) { 
       factorAGL_L = factorL*aglFactor;
       factorAGL_R = factorR*aglFactor;
    }
