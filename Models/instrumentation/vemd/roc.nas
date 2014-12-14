
      
      
      var get_delta=func (current,previous) {return (current-previous);} 
      var state = {new:func {return{parents:[state]};},n1_pct:0,trq_pct:0,t4_pct:0,timestamp:0,};
      
      

      var update_state = func {
         var s = state.new();
	 s.n1_pct=props.globals.getNode("/engines/engine/n1-pct").getValue() or 0;
         s.trq_pct=props.globals.getNode("/sim/model/ec135/torque-pct").getValue() or 0;
	 s.t4_pct=props.globals.getNode("/engines/engine/tot-degc").getValue() or 0;
        
        s.timestamp=systime();
        return s;
    }

     

   
      

    var tvario = {   
      new: func {return {parents:[tvario]};},
      state:{previous:,current:},
      init: func {state.previous=state.new(); state.current=state.new();}, 
      update:func {
   
       state.current = update_state();   
      
       var delta_t = get_delta(state.current.timestamp, state.previous.timestamp);
      
       var deltan1 = get_delta(state.current.n1_pct,state.previous.n1_pct) / delta_t;
       var deltatrq = get_delta(state.current.trq_pct,state.previous.trq_pct) / delta_t;
       var deltat4 = get_delta(state.current.t4_pct,state.previous.t4_pct) / delta_t;
      
     
     
       
       setprop("/instrumentation/VEMD/delta-n1",deltan1);
       setprop("/instrumentation/VEMD/delta-trq",deltatrq);
       setprop("/instrumentation/VEMD/delta-t4",deltat4);
       
    

    
       state.previous = state.current; # save current state for next call
       settimer(func me.update(), 1/20); # update rate
      }
    };

    var tv = tvario.new();
    tv.init();
    tv.update();
   
