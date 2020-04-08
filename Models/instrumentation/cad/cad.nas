var display_colors = {
  "white" : [ 1, 1, 1],
  "black" : [ 0, 0, 0]
};

var fuel_level_properties = {
  "center" : props.globals.getNode("/consumables/fuel/tank[0]/level-kg", 1),
  "right"  : props.globals.getNode("/consumables/fuel/tank[1]/level-kg", 1),
  "left"   : props.globals.getNode("/consumables/fuel/tank[2]/level-kg", 1),
};

var CADDisplay_canvas = canvas.new({
  "name": "CADDisplay",
  "size": [256, 64],
  "view": [101, 20]
});

CADDisplay_canvas.addPlacement({"node": "FuelLevelFigures"});

var CADDisplay_group = CADDisplay_canvas.createGroup();
var canvas_elements = {};
canvas_elements["FuelLevelFigures"] = CADDisplay_group.createChild("text")
                                                      .setTranslation(0, 4)
                                                      .setAlignment("left-top")
                                                      .setFont("LiberationFonts/LiberationMono-Bold.ttf")
                                                      .setFontSize(17, 1.2)
                                                      .setText("LLLCCCRRR");

CADDisplay_group.show().setColor(display_colors["white"]);
CADDisplay_canvas.setColorBackground(display_colors["black"]);

# Using a loop instead of listeners here, because the properties are tied and listeners don't work reliably for tied properties.
var loop = func {
  canvas_elements["FuelLevelFigures"].setText(sprintf("%03d%03d%03d", fuel_level_properties["left"].getValue(), fuel_level_properties["center"].getValue(), fuel_level_properties["right"].getValue()));
  settimer(loop, 0.33333);
}

loop();
