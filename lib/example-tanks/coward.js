exports.name = "Coward"
exports.step = function(dt, tank) 
{
  state.exert(tank.w - tank.x + Math.random() * 1250 - 625, tank.h - tank.y + Math.random() * 1250 - 625);
  var op = tank.radar[0];
  var dx = op.x - tank.x;
  var dy = op.y - tank.y;
  tank.exert(-dx, -dy);
  var theta = Math.atan2(op.y - tank.y, op.x - tank.x);
  tank.turn(theta - tank.bearing);
  tank.fire(3.0);
}
