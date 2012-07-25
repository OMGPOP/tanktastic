exports.name = "Moron";
exports.step = function(dt, state, controller) 
{
  // just move around and shoot randomly. like a moron.
  controller.exert((-20 + Math.random() * 40)/dt, (-20 + Math.random() * 40)/dt);
  controller.set_bearing(state.bearing - 0.05 + Math.random() * 0.1);
  controller.fire(0.5);
}
