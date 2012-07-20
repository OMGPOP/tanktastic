var lx = [];

exports.name = "Aggressivo";
exports.step = function(dt, state)
{
  var op = state.radar[0];
  var t = {x:op.x, y:op.y};
  lx.push(op);
  if(lx.length > 3)
  {
    var time = Math.sqrt(Math.pow(state.x - op.x, 2) + Math.pow(state.y - op.y, 2)) / 400;
    t.x += ((lx[1].x - lx[0].x) / dt) * 0.1 * time;
    t.y += ((lx[1].y - lx[0].y) / dt) * 0.1 * time;
    t.x += ((lx[2].x - lx[1].x) / dt) * 0.3 * time;
    t.y += ((lx[2].y - lx[1].y) / dt) * 0.3 * time;
    t.x += ((lx[3].x - lx[2].x) / dt) * 0.6 * time;
    t.y += ((lx[3].y - lx[2].y) / dt) * 0.6 * time;
    lx.shift();
  }
  var dx = t.x - state.x;
  var dy = t.y - state.y;
  state.exert(dx, dy);
  var theta = Math.atan2(t.y - state.y, t.x - state.x);
  state.turn(theta - state.bearing);
  state.fire(0.2);
}
