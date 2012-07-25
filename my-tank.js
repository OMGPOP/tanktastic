exports.name = "Me!";
exports.step = function(dt, state, controller) 
{
  var opponent = state.closest();
  var dx = opponent.x - state.x;
  var dy = opponent.y - state.y;
  controller.exert(-dx, -dy);
  controller.aim_at(opponent.x, opponent.y);
  controller.fire(3.0);
}

