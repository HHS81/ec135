# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

# This is a generic approach to canvas MFD's

var helionixpath = "Aircraft/ec135/Models/instrumentation/EUcopter-mfd-c/";
var DEBUG = 0;
var DEBUG_TIME = 5;
var ENABLE_PROP_RULES = 0;
var FAST= 1/20; # 20Hz
var SLOW = 1/5; #5Hz

io.include(helionixpath ~ "Nasal/sensor.nas");
io.include(helionixpath ~ "Nasal/filter.nas");
io.include(helionixpath ~ "Nasal/mfd.nas");
io.include(helionixpath ~ "Nasal/fnd.nas");


var font_mapper = func(family, weight)
{
        return "LiberationFonts/LiberationSansNarrow-Bold.ttf";
      
        if( family == "'Liberation Sans'" and weight == "normal" )
                return "LiberationFonts/LiberationSans-Regular.ttf";

        if( family == "'Liberation Sans'" and weight == "bold" )
                return "LiberationFonts/LiberationSans-Regular.ttf";

};
