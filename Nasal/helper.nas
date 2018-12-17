var helper = func{

var brake = props.globals.getNode("/controls/rotor/brake", 1);


if (getprop("/controls/rotor/brake") >1){
setprop("/controls/rotor/brake", 1);
}

if (getprop("/controls/rotor/brake") <0){
setprop("/controls/rotor/brake", 0);
}






settimer(helper, 0.01);
}
helper();
  
