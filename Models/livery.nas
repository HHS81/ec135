# Code from the English Lightning

# sort vector of strings (bubblesort)
#
sort = func(l) {
	while (1) {
		var n = 0;
		for (var i = 0; i < size(l) - 1; i += 1) {
			if (cmp(l[i], l[i + 1]) > 0) {
				var t = l[i + 1];
				l[i + 1] = l[i];
				l[i] = t;
				n += 1;
			}
		}
		if (!n) {
			return l;
		}
	}
}

load = func(live_name) {
	var file = getprop("/sim/fg-root") ~ "/Aircraft/ec135/Models" ~ live_name;
	fgcommand("load", props.Node.new({"file": file}));
}

# material ==========================================================
liveries = {};
file = "";
color = "";
#" ~ getprop("/sim/model[0]") ~ "
foreach (file; directory(getprop("/sim/fg-root") ~ "/Aircraft/ec135/Models/liveries/")) {
	if (substr(file, size(file) - 4) == ".xml") {  
		name = pop(split("/", file));
		livery = split(".",name);
		livery2 = split("_",livery[0]);
		foreach (var tmp;livery2) {
			color = color ~ tmp ~ " ";
		}
		liveries[color] = "/liveries/" ~ file;
		color = "";
	}
}

select_variant = func {
	e = liveries[arg[0]];

	print("Switching texture to " ~ arg[0]);

	# Sets the variant name
	#setprop("sim/model/ec135/livery/variant",arg[0]);

	# Sets the new texture on the aircraft components
	#setprop("sim/model/ec135/livery/material/fuselage/texture", e);
	
	load(e);

#	foreach (var n; props.globals.getNode("sim/model/ec135/livery/material").getChildren()) {
#		setprop("sim/model/ec135/livery/material/" ~ n.getName() ~ "/texture", e);
#	}
}

# dialog ==========================================================

var dialog = {};
i = 0;

showModelSelectDialog = func {
	name = "livery-select-dialog";

	if (contains(dialog, name)) {
		closeModelSelectDialog();
		return;
	}

	var title = 'Select Livery';

	dialog[name] = gui.Widget.new();
	dialog[name].set("layout", "vbox");
	dialog[name].set("name", name);
	dialog[name].set("x", -20);
	dialog[name].set("pref-width", 200);

	# "window" titlebar
	titlebar = dialog[name].addChild("group");
	titlebar.set("layout", "hbox");
	titlebar.addChild("empty").set("stretch", 1);
	titlebar.addChild("text").set("label", title);
	titlebar.addChild("empty").set("stretch", 1);

	dialog[name].addChild("hrule").addChild("dummy");

	w = titlebar.addChild("button");
	w.set("pref-width", 16);
	w.set("pref-height", 16);
	w.set("legend", "");
	w.set("default", 1);
	w.set("keynum", 27);
	w.set("border", 1);
	w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	w.prop().getNode("binding[0]/script", 1).setValue("livery.closeModelSelectDialog()");

	w = dialog[name].addChild("list");
	w.set("halign", "fill");
	w.set("pref-height", 200);
	w.set("property", "/variant");
	foreach (var l; sort(keys(liveries))) {
		w.prop().getChild("value", i, 1).setValue(l);
		i += 1;
	}
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("livery.select_variant(getprop('/variant'))");

	fgcommand("dialog-new", dialog[name].prop());
	gui.showDialog(name);
}


closeModelSelectDialog = func {
	var name = "livery-select-dialog";
	var dlg = props.Node.new({"dialog-name": name});
	fgcommand("dialog-apply", dlg);
	fgcommand("dialog-close", dlg);
	delete(dialog, name);
}


# main() ============================================================

INIT = func {

	variant = getprop("sim/model/ec135/livery/variant");
	#if (variant == nil) {
	#	variant = 0;
	#}
	select_variant(variant);
}

settimer(INIT, 0);
