(function(){

  exports.name = "Coward"

  exports.step = function(dt, state, controller) 
  {
    // move randomly toward the middle
    controller.exert(state.w / 2 - state.x + Math.random() * 120 - 60, state.h / 2 - state.y + Math.random() * 120 - 60);
    var opponent = state.closest();
    var dx = opponent.x - state.x;
    var dy = opponent.y - state.y;
    controller.exert(-dx, -dy);
    controller.aim_at(opponent.x, opponent.y);
    controller.fire(3.0);
  }

})();
