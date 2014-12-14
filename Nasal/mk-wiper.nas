# Lake of Constance Hangar :: M.Kraus
# Avril 2013
# This file is licenced under the terms of the GNU General Public Licence V2 or later
# wiper action

setlistener("/controls/special/wiper-switch", func() {
  wiper_action();  
}, 0, 1);

var wiper_action = func(){

	var ws = getprop("/controls/special/wiper-switch") or 0;
	var d = getprop("/controls/special/wiper-deg") or 0;
    

    
 		if(ws){
 								
 		   		
 		  if(ws == 1){ interpolate("/controls/special/wiper-deg", 45, 2);  
				if (d < -43){        
					interpolate("/controls/special/wiper-deg", 45, 2);  
				}
				if (d > 43){        
					interpolate("/controls/special/wiper-deg", -45,  2);  
				}
				
				settimer(wiper_action, 2.5);
			}
			

			
 		  if(ws == 2){
				if (d < -43){        
					interpolate("/controls/special/wiper-deg", 45, 1);  
				}
				if (d > 43){        
					interpolate("/controls/special/wiper-deg", -45,  1);  
				}
				
				settimer(wiper_action, 1.1);
			}
					
 		 			

		  
		}else{
			interpolate("/controls/special/wiper-deg", -5,  1);
		}   
		
	

};

