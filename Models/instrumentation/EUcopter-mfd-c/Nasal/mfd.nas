# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

# This is a generic approach to canvas MFD's

var canvas_MFD = {
	new: func(canvas_group, svg_filename)
	{
		var m = { parents: [canvas_MFD] };
		m.pfd = canvas_group;
		
                canvas.parsesvg(m.pfd, svg_filename , {'font-mapper': font_mapper});
                
                m.sensors = [];
                m.filters = [];
                m.rules = [];
                
                m.debug = {"read_sensors":0, "translations":0, "text":0, "conditions":0, "fast_text":0, "fast_conditions":0, "rules":0, "t":0};
		m.timers = [];
		m.k = 0; # counter for Nasal tranformation updates
		m.k_tf = 0; # counter for Property Rule transformation updates
		return m;
	},
        
        add_by_id: func(id) {
                if (!contains(me, id)) {                
                      me[id] = me.pfd.getElementById(id);

                      if (me[id] == nil) { 
                            print("WARNING: Non existing SVG ID ",id," !");
                            return nil;
                          }

                      # create a new unity tranform to use it for triggering the canvas update
                      me[id].nodepath = me[id]._node.getPath() ~ "/tf[1]/m";
                      me[id].nodepathval = getprop(me[id].nodepath);

                      return 1;
      
                }
                return 1;
        },
        
        add_trans: func(id, type, params, disable_rules=0) {
                me.add_trans_grp([id,], type, params, disable_rules=0);
        },

        add_trans_grp: func(ids, type, params, disable_rules=0) { 
          
                var elements = [];
                var p = {};
                me.init_params(p, params);
                
                var is_const = (p.function==nil and p.sensor==nil and p.prop==nil);
                
                foreach (var i; ids) {
                   var x = me._add_trans(i, type);
                   if (x==nil) 
                       die("error in adding svg transformation");
                       
                   # check if element is suitable for a prop rule update

                   if (!disable_rules and me.k_tf<200 and ENABLE_PROP_RULES and checkrules(p) ) {
                       # setup a property rule, no sensors and filters needed anymore
                       me.setup_property_rule(i, x, p);                       
                   } else {
                       append(elements, x);
                   }
                }
                   
                if (size(elements)==0)
                   return;
                               
                var f = Filter.new(p);
                append(me.filters, f);
                
                if (is_const) {
                    # make filter a constant value by using offset
                    f.val = f.offset;
                
                } elsif (p.sensor == nil) {    
                    var s = Sensor.new(p);
                    append(me.sensors,s);       

                    # register filter callback at sensor
                    s.register([f,"update"]);
                } else {
                    # if a sensor is already referenced, use this
                    p.sensor.register([f,"update"]);
                }
                
                foreach (var e; elements) {
                    # establish callback method update to the trans. element
                    me._add_callback(e["id"], e["type"]);
                    f.register([ me[e["id"]], "update" ] );
                }
                
                if (is_const) {
                    #make one update call to set the constant values.
                    f.update(0);
                }
                
        },
        
        _add_trans: func(id, type) {
                # create the new transform element for the canvas SVG animation
                # return the active transformation element to use for animation 
                
                var thistrafo = {};
                
                thistrafo["id"] = nil;
                thistrafo["type"] = me.set_type(type);
                
                if (me.add_by_id(id) == nil)
                      return nil;
                
                var c = me[id].getCenter();
                thistrafo["center"] = c;
                
                if (type == "x-scale" or type == "y-scale" or type== "rotation")
                      me[id].createTransform().setTranslation(-c[0], -c[1]);
                      
                me[id ~ "_t" ~ me.k] = me[id].createTransform();
                      
                if (type == "x-scale" or type == "y-scale" or type== "rotation")
                      me[id].createTransform().setTranslation(c[0], c[1]);

                thistrafo["id"] = id ~ "_t" ~ me.k;
                return thistrafo;
        },
        
        set_type: func (x) {
                # improve speed by converting string to int
                return (x=="x-shift") ? "1" :
                  (x=="y-shift") ? "2" :
                  (x=="rotation") ? "3" :
                  (x=="x-scale") ? "4" :
                  (x=="y-scale") ? "5" : "0"; 
        },                
        
        add_filter: func(params, type) {
                var x = {};
                me.init_params(x, params);
                x._type = type;
                
                if (x.sensor != nil) {
                   var f = Filter.new(x);
                   append(me.filters, f);
                   return f;
                }
                
                return x.sensor;
                
        },                
        
        _add_callback: func (this, transtype) {

              # construct an update method for the transformation to allow the 
              # update via the Filter objects callback
                
              if (transtype == "1") 
                  me[this].update = func (y) me.setTranslation(y, 0);
              elsif (transtype == "2") 
                  me[this].update = func (y) me.setTranslation(0, y);
              elsif (transtype == "3") 
                  me[this].update = func (y) me.setRotation(y*D2R);
              elsif (transtype == "4") 
                  me[this].update = func (y) me.setScale(y, 1);
              elsif (transtype == "5") 
                  me[this].update = func (y) me.setScale(1, y);
        },
        add_text: func(id, params) {
                me.add_text_grp([id,],params);
        },
        add_text_grp: func(ids, params) {
                var elements = [];
                var p = {};
                me.init_params(p, params);
                
                var is_const = (p.function==nil and p.sensor==nil and p.prop==nil);
                
                foreach (var i; ids) {
                   var x = me._add_text(i, p);
                   if (x==nil) 
                       die("error in adding text");
                   
                   if (is_const)  
                     me[x.id].me.setTextFast(""~p.offset);
                   else  
                     append(elements, x);
                }
                
                if (is_const) 
                    return;
                    
                if (p.sensor == nil) {  
                    p["text"] = 1;
                    var s = Sensor.new(p);
                    append(me.sensors, s);      
                } else {
                    # if a sensor is already referenced, use this
                    var s = p.sensor;
                }
                
                foreach (var e; elements) {
                    # register callback method update_c to the element
                    if (p.format == nil) {
                        # non-numeric value
                        s.register( [me[e["id"]], "update_t"] );
                    } else {
                        # add filter
                        var f = Filter.new(p);
                        append(me.filters, f);                        
                        s.register( [f, "update"] );
                        f.register( [me[e["id"]], "update_t"]);                       
                    }
                }
        },                
        
        _add_text: func(id, params) {                
                var thistxt = {};
                thistxt["id"] = id;
                
                if (me.add_by_id(id) == nil)
                      return;
                    
                me[id].enableFast();
                me[id].update_t = func (y) me.setTextFast(y);
                return thistxt;
        },
        add_cond: func(id, params) {
                me.add_cond_grp([id,], params);
        },       
        add_cond_grp: func(ids, params) {
                var elements = [];
                var p = {};
                me.init_params(p, params);
                
                var is_const = (p.function==nil and p.sensor==nil and p.prop==nil);
                
                foreach (var i; ids) {
                   var x = me._add_cond(i, p);
                   if (x==nil) 
                       die("error in adding condition");
                   
                   if (is_const)  
                     if (p.offset) me[x.id].show() else me[x.id].hide();
                   else  
                     append(elements, x);
                }
                
                if (is_const) 
                    return;
                    
                if (p.sensor == nil) {  
                    p["text"]=1;
                    var s = Sensor.new(p);
                    append(me.sensors, s);      
                } else {
                    # if a sensor is already referenced, use this
                    var s = p.sensor;
                }
                
                foreach (var e; elements) {
                    # register callback method update_c to the element
                    s.register( [me[e["id"]], "update_c"] );
                }
        },
        
        _add_cond: func(id, params) {
                var thistxt = {};
                thistxt["id"] = id;
                
                if (me.add_by_id(id) == nil)
                      return;
                
                me[id].update_c = func (y) if (y) me.show() else me.hide();

                return thistxt;
        },
        
	newMFD: func() {
              me.debug_out = maketimer(DEBUG_TIME, func me.show_debug() ); 
              if (DEBUG) { 
                  me.debug_out.start();
                  print("canvas MFD using ", me.k, " transforms");
                  print("canvas MFD using ", me.k_tf, " rules");
              }
              
              # spawn new thread to avoid frame rate "stutter". however, given the talk
              # on the forum threads might be really, really problematic when async. accessing
              # the property tree !
              
              thread.newthread( func {
                  me.update_timer = maketimer(FAST, func me.update() );
                  me.update_timer.start(); 
                  }
              );
	},
        show_debug: func () 
        {       
                var total = 0;       
                me.debug.t += DEBUG_TIME;
                
                foreach(var s; ["read_sensors","translations","text","conditions","fast_text","fast_conditions","rules"]) 
                    total += me.debug[s];
                                
                if (total>0) {
                    var out = {};
                    foreach(var s; ["read_sensors","translations","text","conditions","fast_text","fast_conditions","rules"]) 
                         out[s] = int( me.debug[s] / total * 100 );
                         
                    out.avg_ms = int(total / me.debug.t * 1000);
                    debug.dump( out );
                }
        },
        trigger_rule: func (id) 
        {    
                # trigger update of a property rule trafo by setting a trivial transformation
                # of the 1st transformation matrix element
                
                setprop(me[id].nodepath, me[id].nodepathval);
                #setprop("canvas/by-index/texture[3]/group/group/tf[1]/m",1);
        },                    
        update: func()
        {       
                  
                me["debug"]["rules"] += debug.benchmark_time(
                  func () {
                    foreach(var i; me.rules) 
                       me.trigger_rule(i);
                  } 
                );
                  
        },
        init_params: func(x, params) {
        
              # note: optional named arguments did not work, therefore a hash is used
              # init some transformation default parameters
              
              x["function"] = contains(params, "function") ? params.function : nil;
              x["prop"] = contains(params, "prop") ? params.prop : nil;
              x["sensor"] = contains(params, "sensor") ? params.sensor: nil;
              x["scale"] = contains(params, "scale") ? params.scale : 1.0;
              x["offset"] = contains(params, "offset") ? params.offset : 0.0;
              x["mod"] = contains(params, "mod") ? params.mod : nil;
              x["max"] = contains(params, "max") ? params.max : 10000000000000000000;
              x["min"] = contains(params, "min") ? params.min : -10000000000000000000;
              x["format"] = contains(params, "format") ? params.format: nil;
              x["trunc"] = contains(params, "trunc") ? ((params.trunc == "int") ? 1 : 0) : 0;
              x["abs"] = contains(params, "trunc") ? ((params.trunc == "abs") ? 1 : 0) : 0;
              x["delta"] = contains(params, "delta") ? params.delta : 0;
              x["_last"] = nil;
              x["_changed"] = 1; # update once on first loop
              x["_val"] = nil;
              x["_strval"] = nil;
              x["_type"] = nil;
              
        },
        setup_property_rule: func(svgid, trans, x) {
          
              # make calculation of transform in a property rule
              # to reduce Nasal overhead
              # the output is aliased to the correct tranformation
              # matrix
              # however, the aliased property does not trigger an automatic
              # update of the canvas.
            
              if (!contains(me.rules, svgid))
                  append(me.rules, svgid);
              
              proproot = "canvas/rules/rule[" ~ me.k_tf ~ "]/";              
              #print (svgid," ", me[trans.id].a.getPath());
                            
              props.globals.getNode(proproot~"active", 1).setBoolValue(1);
              props.globals.getNode(proproot~"r-active", 1).setBoolValue(0);
              
              setprop(proproot~"name", svgid);             
              setprop(proproot~"offset", -x.offset/x.scale);
              setprop(proproot~"scale", x.scale);
              setprop(proproot~"min", x.min);
              setprop(proproot~"max", x.max);
              setprop(proproot~"periodmin", (x.mod==nil) ? -10000000000000000000 : 0);
              setprop(proproot~"periodmax", (x.mod==nil) ? 10000000000000000000 : x.mod);
              setprop(proproot~"abs", x.abs);
              
              var nodeIn = nil;
              var propIn = "";
              var propOut = proproot~"out";
              
              # alias the input node:
              if (x.sensor != nil)
                 propIn = x.sensor.prop;
              elsif (x.prop != nil)
                 propIn = x.prop;
              else {
                 #account for const. transformations
                 propIn = "const/zero";
                 setprop(propIn, 0.0);
              }
           
              nodeIn = props.globals.getNode(proproot~"in");
              nodeIn.alias(propIn);
              
              # alias the correct output node/transform matrix element:
              #tfm : {x-scale:"a", y-scale:"d", x-shift:"e",y-shift:"f"},
              
              id=trans.id;              
              if  (trans.type == "1")
                  #x-shift
                  me[id].e.alias(propOut);
              elsif (trans.type == "2")
                  #y-shift
                  me[id].f.alias(propOut);
              elsif (trans.type == "4") 
                  #x-scale
                  me[id].a.alias(propOut);
              elsif (trans.type == "5") 
                  #y-scale
                  me[id].d.alias(propOut);
              elsif (trans.type == "3") {
                  # setup the rotation matrix                  
                  me[id].a.alias(proproot~"cos");
                  me[id].b.alias(proproot~"sin");
                  me[id].c.alias(proproot~"m-sin");
                  me[id].d.alias(proproot~"cos");
                  props.globals.getNode(proproot~"r-active", 1).setBoolValue(1);
              }
              
              me.k_tf += 1;
              return 1;
        }        
};
   
     
# linear interpolator class
# adopted from Zivko Edge
# original author Torsten Dreyer

var LUT = {
  new: func(pairs)
  {
    var m = { parents: [ LUT ] };
    m.pairs = pairs;
    m.n = size(pairs)-1;
    return m;
  },
  get: func(x)
  {
    if( x <= me.pairs[0][0] ) {
      return me.pairs[0][1];
    }
    if( x >= me.pairs[me.n][0] ) {
      return me.pairs[me.n][1];
    }
    for( var i = 0; i < me.n; i+=1 ) {
      if( x > me.pairs[i][0] and x <= me.pairs[i+1][0] ) {
        var x1 = me.pairs[i][0];
        var x2 = me.pairs[i+1][0];
        var y1 = me.pairs[i][1];
        var y2 = me.pairs[i+1][1];
        return (x-x1)/(x2-x1)*(y2-y1)+y1;
      }
    }
    return me.pairs[i][1];
  }
};

var checkrules = func (p) {
    if (p.prop != nil)
        return 1;        
    if (p.sensor != nil)
      if (p.sensor.prop != nil)
        return 1;                      
    return 0;
};
