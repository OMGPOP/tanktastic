exports.name = "Aggressivo";
exports.step = function(dt, state, controller)
{
  var opponent = state.closest();
  // guess where the opponent will be when the bullet reaches him
  var prediction = predict(opponent, dt, state);
  // aim at the guess
  controller.aim_at(prediction.x, prediction.y);
  // move in that direction
  controller.exert(prediction.x - state.x, prediction.y - state.y);
  controller.fire(0.1);
}

var lx = [];
var predict = function(target, dt, state)
{
  lx.push(target);
  var t = {x:target.x, y:target.y}; // clone to build prediction
  if(lx.length > 3)
  {
    // solve for amount of time until bullet fired now hits target's current position
    var time = Math.sqrt(Math.pow(state.x - target.x, 2), + Math.pow(state.y - target.y, 2)) / state.muzzle_speed;
    // weight prediction, favoring recent position readings
    t.x += ((lx[1].x - lx[0].x) / dt) * 0.1 * time;
    t.y += ((lx[1].y - lx[0].y) / dt) * 0.1 * time;
    t.x += ((lx[2].x - lx[1].x) / dt) * 0.3 * time;
    t.y += ((lx[2].y - lx[1].y) / dt) * 0.3 * time;
    t.x += ((lx[3].x - lx[2].x) / dt) * 0.6 * time;
    t.y += ((lx[3].y - lx[2].y) / dt) * 0.6 * time;
    lx.shift(); // lose the oldest position
  }
  return t;
}
