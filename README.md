Tanktastic
==========

Tanktastic is an AI-driven tank battle game. AIs control Roomba-styled tanks through a simple API, competing against each other to be the last standing. 

Getting Started
---------------

Clone this repo and run the example:
```bash
git clone git@github.com:OMGPOP/tanktastic.git
open tanktastic/tanktastic.html
```
You should see a match among the 3 example tanks, Coward, Moron, and Aggressivo, running in your default browser. If you refersh the page, you'll notice the same match plays again. This is because Tanktastic uses a seeded random number generator to deterministically reproduce specific matches. This makes testing a bit easier and tournaments fairer. To change the seed, add a query string to the end of the address:  

![Seeding the RNG](https://s3.amazonaws.com/challenges.engineering/images/tanktastic-query.png "Seeding the RNG")

Next, let's add your tank to the mix. There's a tank AI file included called ```my-tank.js``` which is just a simpler form of Coward (no offense). To add yourself to the match, uncomment its inclusion in the ```tanks``` definition in tanktastic.html:
```javascript
var tanks = [
				"lib/example-tanks/aggressivo.js",
				// "my-tank.js",
				"lib/example-tanks/coward.js",
				"lib/example-tanks/moron.js"
			];
```
### Defining a Tank
Defining a tank is very simple, you just need to provide a name for your tank and a method called step, which gets called each game loop, attaching them to the ```exports``` object:
```javascript
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
```
Note that ```step``` takes 3 arguments, ```dt```, ```state``` and ```controller```. ```dt``` is the _delta time_, or the amount of time (in seconds) that has elapsed since the last game loop. ```state``` is what represents the state of the game; a collection of all the information you have about the game at the current time. ```controller``` provides methods for controlling your tank. 

### API
```state``` has the following properties:

1. ```x```: position of your tank along the x-axis (pixels)
2. ```y```: position of your tank along the y-axis (pixels)
3. ```w```: the total width of the rectangular arena (constant)
4. ```h```: the total height of the arena (constant)
5. ```radius```: your tank's radius
6. ```vx```: your tank's speed along the x-axis (pixels per second)
7. ```vy```: your tank's speed along the y-axis (pixels per second)
8. ```bearing```: your tank's turret orientation (in radians)
9. ```gun_heat```: your gun's current temperature
10. ```life```: how much life you have left (```[0, 100]```)
11. ```muzzle_speed```: the speed at which bullets are shot (constant, pixels per second)
12. ```radar```: a list of ```(x,y)``` pairs representing tanks scanned by your radar. 
13. ```obstacles```: a list of ```(x,y,r)``` objects, where ```x, y``` is the position of the obstacle and ```r``` is its radius

The only property that might not be self-explanatory is ```gun_heat```. Your gun must be completely cool to fire. When you shoot, your gun heats up according to how powerful the shot is.

```state``` also defines a convenience method ```closest```, which gets the closest scanned tank in ```state.radar```.

The methods defined on ```controller``` to control your tank are:

1. ```set_bearing(bearing)```: this sets the orientation of your turret immediately (radians)
2. ```fire(power)```: this makes a request to fire at the given power (seconds to cooldown; ```[0.1, 3.0]```)
3. ```exert(fx, fy)```: exert a force on your tank in the given x and y directions
4. ```aim_at(x, y)```: convenience method to turn your turret to aim at the given coordinate

### Considerations
A couple things necessitate a bit more detail. 

1. Your radar isn't perfect; there's some noise in the signal, so the ```(x,y)``` readings of your opponent tanks aren't precise. The error in the reading has a normal distribution with _&mu;_ = 0 and _&sigma;_ = _&gamma;_ log<sub>10</sub> _d<sub>i</sub>_, where _d<sub>i</sub>_ is the distance to the _i_ th scanned tank and _&gamma;_ is a constant. This means that the error is a function of the distance; closer scans are more accurate.
2. The amount of damage a bullet will do is a non-linear function of the power. Here's the function and its graph over the valid range of firepowers:

![Firepower function](https://s3.amazonaws.com/challenges.engineering/images/tanktastic-power.png "Firepower function")
