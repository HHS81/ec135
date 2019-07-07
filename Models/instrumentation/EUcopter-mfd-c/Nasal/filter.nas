# Filter class to make linear transforms for element animation and callback of element animation.
# the filter object holds a list callbacks of other objects (usually svg transforms) that
# it calls to update those elements for any filter updates.

var Filter = {
    new: func(param) {
          var m = { parents: [Filter] };

          m.callbacks=[];
          m["scale"] = contains(param, "scale") ? param.scale : 1.0;
          m["offset"] = contains(param, "offset") ? param.offset : 0.0;
          m["mod"] = contains(param, "mod") ? param.mod : nil;
          m["max"] = contains(param, "max") ? param.max : 10000000000000000000;
          m["min"] = contains(param, "min") ? param.min : -10000000000000000000;
          m["format"] = contains(param, "format") ? param.format: nil;
          m["trunc"] = contains(param, "trunc") ? ((param.trunc == 1) ? 1 : 0) : 0;
          m["abs"] = contains(param, "abs") ? ((param.abs == 1) ? 1 : 0) : 0;
          m["val"] = nil;
          
          #this allows to call the update method via a string reference
          
          m["update"] = func (y) {
    
            if (me.mod)
                var p = math.fmod(y or 0, me.mod);
            else
                var p = math.clamp(y or 0, me.min, me.max);
            
            var out = p * me.scale + me.offset;
            if (me.trunc == 1) out = int(out);
            if (me.abs == 1) out = abs(out);
            
            # check if we need a string output
            me.val = (me.format == nil) ? out : sprintf(me.format, out);
            me._callback();
                      
          };          
          return m;
    },

    _callback: func () {       
       foreach(var cb; me.callbacks) {
          #this allow to pass the name of the method to call as a string
          call(cb[0][cb[1]], [me.val,], cb[0]);
          }
    },
    register: func (obj) {
       append(me.callbacks, obj);
    },
    get: func() {
       return me.val;
    }    
};
