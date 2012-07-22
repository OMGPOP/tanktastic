exports.name = "Coward"
exports.step = function(dt, state) 
{
	// move randomly toward the middle
  state.exert(state.w / 2 - state.x + Math.random() * 120 - 60, state.h / 2 - state.y + Math.random() * 120 - 60);
  var opponent = state.closest();
  var dx = opponent.x - state.x;
  var dy = opponent.y - state.y;
  state.exert(-dx, -dy);
	state.aim_at(opponent.x, opponent.y);
  state.fire(3.0);
}
