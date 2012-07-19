exports.name = "Moron"
exports.step = function(dt, tank) 
{
  tank.exert((-20 + Math.random() * 10)/dt, (-20 + Math.random() * 10)/dt);
  tank.fire(0.5);
}
