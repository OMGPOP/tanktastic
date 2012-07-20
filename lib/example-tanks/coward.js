exports.name = "Coward"
exports.step = function(dt, state) 
{
  state.exert(state.w - state.x + Math.random() * 1250 - 625, state.h - state.y + Math.random() * 1250 - 625);
  var op = state.radar[0];
  var dx = op.x - state.x;
  var dy = op.y - state.y;
  state.exert(-dx, -dy);
  var theta = Math.atan2(op.y - state.y, op.x - state.x);
  state.turn(theta - state.bearing);
  state.fire(3.0);
}
