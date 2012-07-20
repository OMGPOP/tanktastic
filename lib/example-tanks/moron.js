exports.name = "Moron"
exports.step = function(dt, state) 
{
  state.exert((-20 + Math.random() * 40)/dt, (-20 + Math.random() * 40)/dt);
  state.turn(-0.05 + Math.random() * 0.1);
  state.fire(0.5);
}
