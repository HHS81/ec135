#code snippets taken from the Boeing CDU and KT-76C by Gary Neely

GTX330Input             = props.globals.getNode("/instrumentation/GTX330/input", 1);
GTX330_code	 = props.globals.getNode("/instrumentation/transponder/id-code", 1);
GTX330_goodcode	 = props.globals.getNode("/instrumentation/transponder/goodcode", 1);

var GTX330_code		= props.globals.getNode("/instrumentation/transponder/id-code");
var GTX330_Input             = props.globals.getNode("/instrumentation/GTX330/input");
var GTX330_goodcode	= props.globals.getNode("/instrumentation/transponder/goodcode");

var GTX330_codes		= [];						# Array for 4 code digits
var GTX330_last		= [];						# Holds copy of last known good code



var input = func(i) {
		#setprop("/instrumentation/GTX330/input",getprop("/instrumentation/GTX330/input")~i);
  append(GTX330_codes,i);
GTX330_copycode();

 if (size(GTX330_codes) >= 4) { return 0; }
 if (size(GTX330_codes) == 4) {						# If we now have 4 digits, treat as a good
   GTX330_last = GTX330_codes;						# code and save; flag that we have a good
    GTX330_goodcode.setValue(1);	
}  else {
    GTX330_goodcode.setValue(0);
  }
 GTX330_copycode();
}

var delete = func {
  if (size(GTX330_codes)) {
    pop(GTX330_codes);
    GTX330_copycode();
  }
}
	


var GTX330_copycode = func {
#var GTX330_Input             = props.globals.getNode("/instrumentation/GTX330/input");
  if (!size(GTX330_codes)) {
    GTX330_code.setValue(0);
    return 0;
  }
  var codestr = "";
  for(var i=0; i < size(GTX330_codes); i+=1) {
    codestr = codestr ~ GTX330_codes[i];
  }
  var code = 0;
  code = code + codestr;
  GTX330_code.setValue(code);
}


	
#var delete = func {
#		var length = size(getprop("/instrumentation/GTX330/input")) - 1;
#		setprop("/instrumentation/GTX330/input",substr(getprop("/instrumentation/GTX330/input"),0,length));
#	}
	
var i = 0;

var plusminus = func {	
	var end = size(getprop("/instrumentation/GTX/input"));
	var start = end - 1;
	var lastchar = substr(getprop("/instrumentation/GTX/input"),start,end);
	if (lastchar == "+"){
		me.delete();
		me.input('-');
		}
	if (lastchar == "-"){
		me.delete();
		me.input('+');
		}
	if ((lastchar != "-") and (lastchar != "+")){
		me.input('+');
		}
	}
	




