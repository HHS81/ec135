################################################################################
#
# Boeing 787-8 Dreamliner Terrain Map (also used in other aircraft)
#
# The idea about getting a terrain map without compromising much frame-rate is
# to sweep the changes across the screen instead of getting the whole screen at
# once. Another idea here is to interpolate between 2 points and 'assume' what
# would be there. That way, say in a line of 32, instead of getting all 32
# points, we could get just 16 and interpolate the rest to this and it would be
# almost just as good.
#
# Licensed along with the 787-8 under GNU GPL v2
#
################################################################################

# by litzi: filter for terrain above height, 
# use relative hight steps for color coding of terrain

var row = 0;
var RAD2DEG = 57.2957795;
var DEG2RAD = 0.016774532925;
var terrain = "/instrumentation/terrain-map/pixels/";
var terrain_full = "/instrumentation/terrain-map[1]/pixels/";
var clamp = func(v, min = 0, max = 1) v < min ? min : v > max ? max : v;

# Function to get Elevation at latitude and longitude



var get_elevation = func (lat, lon) {
	var info = geodinfo(lat, lon);
	if (info != nil) {          
          return [ info[0] * 3.2808399, (info[1] == nil) ? 1 : info[1].solid ];
        } else { 
          return nil; 
        }
}


var terrain_map = {

	init : func {
		me.UPDATE_INTERVAL = 0.025;
		me.loopid = 0;

		me.reset();
	},

	update : func {

		if (getprop("/instrumentation/efis/input/TERR")) {

			var pos_lon = getprop("/position/longitude-deg");
			var pos_lat = getprop("/position/latitude-deg");
			var heading = getprop("orientation/heading-magnetic-deg");
			var terrmode = getprop("/instrumentation/efis/dmap/terrainmode");
			var emin = 99999;
			var emax = -99999;

			#setprop("/controls/mfd/terrain-map/range", getprop("/instrumentation/ndfull/range"));

			#var range = getprop("/instrumentation/efis/nd/display-range");
                        var range = getprop("/instrumentation/efis/navd/range") * 3.125;
			var displaymode = getprop("instrumentation/efis[0]/nd/display-mode");


			### Same calculations but for the fullscreen ND, that means RANGE matters

			# First get all the points (16x16)

			for (var col = 0; col <= 32; col += 2)

			{
	
				var proj_lon = pos_lon + ((-1 * (col-16) * (range/32) * math.sin(DEG2RAD * (heading - 90))) / 60);
				var proj_lat = pos_lat + ((-1 * (col-16) * (range/32) * math.cos(DEG2RAD * (heading - 90))) / 60);
				
				
				if (displaymode == 'ARC') { #just represent ahead
					var point_lon = proj_lon + ((row * (range/30) / 60) * math.sin(DEG2RAD * heading));
					var point_lat = proj_lat + ((row * (range/30) / 60) * math.cos(DEG2RAD * heading));

				} else {  # Represent ahead and back
					var point_lon = proj_lon + (((row-16) * (range/32) / 60) * math.sin(DEG2RAD * heading));
					var point_lat = proj_lat + (((row-16) * (range/32) / 60) * math.cos(DEG2RAD * heading));
				}
				
				var e = get_elevation(point_lat, point_lon);
				if (e != nil) { 
                                  setprop(terrain ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/elevation-ft", e[0] );
                                  setprop(terrain ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/flag", e[1] );
                                } else {
                                  setprop(terrain ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/elevation-ft", 0 );
                                  setprop(terrain ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/flag", -1 );
                                }  

			}

			# Interpolate the rest of the points in each column

			for (var col = 1; col <= 31; col += 2)
			{

				var elev_prev = getprop(terrain ~ "row[" ~ row ~ "]/col[" ~ (col - 1) ~ "]/elevation-ft");
				var elev_next = getprop(terrain ~ "row[" ~ row ~ "]/col[" ~ (col + 1) ~ "]/elevation-ft");
				var elevation = (elev_prev + elev_next) / 2;
				
				emin = (elevation < emin) ?  elevation : emin;
                                emax = (elevation > emax) ?  elevation : emax;
                                var flag = getprop(terrain ~ "row[" ~ row ~ "]/col[" ~ (col - 1) ~ "]/flag");

				setprop(terrain ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/elevation-ft", elevation);
                                setprop(terrain ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/flag", flag);
			}

                        # generate relative height steps
                        var altitude = getprop("position/altitude-ft") or 0;
                        # scale max/min terrain height to -7 .. +7 = 15 levels
                        
                        var escale = clamp( (emax - emin)/15 or 0, 100, 2000);

                        for (var col = 0; col <= 31; col += 1)
                        {
                                # rel. terrain height above AC +3000 ft in 10 300 ft steps
                                # below AC scaled to 10 height steps
                                
                                var elevation = getprop(terrain ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/elevation-ft") or 0;
                                var flag = getprop(terrain ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/flag") or 0;
                                
                                var hstep = int((elevation - emin) / escale) - 7;
                                
                                # level -8 reserved for sea level (=non solid) in blue
                                # set 100 for invalid height or terrain below a/c in terrain mode
                                
                                if (terrmode) {
                                  hstep = (elevation < altitude) ? 100 : clamp(hstep, -7, 7);
                                } else {
                                  hstep = (flag == 0) ? -8 : (flag == -1) ? 100 : clamp(hstep, -7, 7);
                                }
                                #var hstep = (ediff>0) ? ediff/300 : -8;
                                #var hstep = (getprop(terrain ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/elevation-ft") or 0) / 300 - 8;
                                setprop(terrain ~ "row[" ~ row ~ "]/col[" ~ col ~ "]/rel-height-step", hstep);

                        }  
			row += 1;

			if (row == 32) row = 0;

		}

    	},

        reset : func {
            me.loopid += 1;
            me._loop_(me.loopid);
        },
        _loop_ : func(id) {
            id == me.loopid or return;
            me.update();
            settimer(func { me._loop_(id); }, me.UPDATE_INTERVAL);
        }

};

setlistener("sim/signals/fdm-initialized", func {
	terrain_map.init();
	print("Terrain Map ......... Initialized");
});



