##residual thrust simulation##
#rt=(y*(torque+x) * rpm)
#x= thrust at zero torque, maybe for the beginning 1/10 of thrust at max torque
#y=mean value to get at the end the maximum residual thrust
#real values only found for MTU DB 720, used on german Bell UH1-D: max power 993KW, residual thrust= 941 N (96kp)

var residualthrust =  func {


var rpm_1 = props.globals.getNode("engines/engine/n2-rpm").getValue() or 0;
var rpm_2 = props.globals.getNode("engines/engine[1]/n2-rpm").getValue() or 0;
var torque = props.globals.getNode("sim/model/ec135/torque-pct").getValue() or 0;

var P1 = 100/(33290/rpm_1);
var P2 = 100/(33290/rpm_2);
#setprop ("engines/engine/P1", P1);


var rt1= (0.00007*(torque + 12.0)*P1);
var rt2= (0.00007*(torque + 12.0)*P2);

if (rpm_1 >1){
setprop ("engines/engine/residualthrust", rt1);
#setprop ("engines/engine/P1", P1);
}

if (rpm_2 >1){
setprop ("engines/engine[1]/residualthrust", rt2);
}

settimer(residualthrust, 0.1);
}
residualthrust();
