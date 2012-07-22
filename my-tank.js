exports.name = "Me!";
exports.step = function(dt, state) 
{
  var opponent = state.closest();
  var dx = opponent.x - state.x;
  var dy = opponent.y - state.y;
  state.exert(-dx, -dy);
	state.aim_at(opponent.x, opponent.y);
  state.fire(3.0);
}
