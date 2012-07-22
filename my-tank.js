exports.name = "Me!"
exports.step = function(dt, state) 
{
	// just move around and shoot randomly. like a moron.
  state.exert((-20 + Math.random() * 40)/dt, (-20 + Math.random() * 40)/dt);
  state.set_bearing(state.bearing - 0.05 + Math.random() * 0.1);
  state.fire(0.5);
}
