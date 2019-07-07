# Sensor class to avoid repeated readout of properties.
#
# Each sensor object holds a list callbacks to other objects (usually filters or canvas elements) that
# it calls to update in case of sensor value change
# (original concept seen in Thorstens Zivko Edge)

var Sensor = {
    new: func(param) {
            var m = { parents: [Sensor] };
            
            m.prop = contains(param, "prop") ? param.prop : nil;
            m.function = contains(param, "function") ? param.function : nil;
            m.thres = contains(param, "thres") ? param.thres : 0;
            m.disable = contains(param, "disable_listener") ? param.disable_listener : 0;
            m.text = contains(param, "text") ? param.text: 0;
            m.val = nil;
            m.callbacks = [];
            m.changed = 1; #legacy
            
            setlistener("sim/signals/fdm-initialized", func() { 
              if (m.function == nil) 
                  m._update_prop();
              else 
                  m._update_func();
            });
            
            if (m.disable>0 or m.function != nil) {
                thread.newthread( func {
                    if (m.function == nil)
                       m.timer = maketimer(m.disable, func m._update_prop() );
                    else
                       m.timer = maketimer(m.disable, func m._update_func() );
                    m.timer.start();
                });                  
            } elsif (m.prop != nil) {
                thread.newthread( func setlistener(m.prop , func m._update_prop() ));
                #setlistener(m.prop , func m._update_prop());
            } else {
                # a constant value
                die("Sensor.new(): must give either 'function' or 'prop' argument!")
            }            
            return m;
        },
    _update_prop: func () {
        me._check( getprop(me.prop) );
    },
    _update_func: func () {
        me._check( me.function() );
    }, 
    _check: func (x) {
       if (x == nil) 
           return;
         
       if (me.val == nil) {
           me.val = x;
           me._callback();
           return;
       }
       
       if (me.text) {
          if (cmp(""~me.val, ""~x) != 0) {
              me.val = x;
              me._callback();
          }         
       } else {
          if (abs(me.val-x) > me.thres) {
              me.val = x;
              me._callback();
          }
       }
    },
    _callback: func () {       
       foreach(var cb; me.callbacks) {
          #this allow to pass the name of the method to call as a string
          #debug.dump(cb);
          call(cb[0][cb[1]], [me.val,], cb[0]);
       }
    },
    register: func (obj) {
       append(me.callbacks, obj);
    },
    get: func () {
       return me.val;
    }
};