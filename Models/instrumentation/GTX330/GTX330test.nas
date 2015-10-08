#code snippets taken from the Boeing CDU and KT-76C by Gary Neely

var transponder_code		= props.globals.getNode("/instrumentation/transponder/id-code");
var GTX330_codes		= [];						# Array for 4 code digits
var GTX330Input             = props.globals.getNode("/instrumentation/GTX330/input");
var GTX330_goodcode	= props.globals.getNode("/instrumentation/transponder/goodcode");

var GTX330_codes		= [];						# Array for 4 code digits
var GTX330_last		= [];						# Holds copy of last known good code


var GTX330_button_code = func(i) {					# i = 0-7
    if (size(GTX330_codes) >= 4) { return 0; }				# Max of 4 digits
  append(GTX330_codes,i);
  if (size(GTX330_codes) == 4) {						# If we now have 4 digits, treat as a good
    GTX330_last = GTX330_codes;						# code and save; flag that we have a good
    GTX330_goodcode.setValue(1);						# code available to send
  }
  else {
    GTX330_goodcode.setValue(0);
  }
  GTX330_copycode();
  #kt76c_entry_clock(0);
}

									# Clear last digit (pop from list)
var delete = func {
  if (size(GTX330_codes)) {
    pop(GTX330_codes);
    GTX330_copycode();
  }
}
	
var copycode = func {
 if (size(GTX330Input) == 4) {						
    GTX330_goodcode.setValue(1);	
}else
{ GTX330_goodcode.setValue(0);
}
}

var codesent = func {
if ((GTX330_goodcode) ==1){
transponder_code.setValue (GTX330Input);
}
}



