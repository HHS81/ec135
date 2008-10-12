
aphb = props.globals.getNode( "/autopilot/settings/heading-bug-deg" );
v = aphb.getValue();
if( v == nil ) {
  aphb.setDoubleValue( 0.0 );
}
rad = props.globals.getNode( "/instrumentation/nav[0]/radials/selected-deg" );
v = rad.getValue();
if( v == nil ) {
  rad.setDoubleValue( 0.0 );
}

hsihb = props.globals.getNode( "/instrumentation/hsi/heading-bug-rotation-deg", "true" );
hsics = props.globals.getNode( "/instrumentation/hsi/cursor-rotation-deg", "true" );

setlistener( "/instrumentation/heading-indicator/indicated-heading-deg", func(n) {
  h = n.getValue();

  v = h - aphb.getValue();
  if( v < 0.0 ) {
    v = v + 360.0;
  }
  hsihb.setDoubleValue( v );

  v = h - rad.getValue();
  if( v < 0.0 ) {
    v = v + 360.0;
  }
  hsics.setDoubleValue( v );
});
