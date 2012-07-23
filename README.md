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
exports.step = function(dt, state) 
{
  var opponent = state.closest();
  var dx = opponent.x - state.x;
  var dy = opponent.y - state.y;
  state.exert(-dx, -dy);
  state.aim_at(opponent.x, opponent.y);
  state.fire(3.0);
}
```
Note that ```step``` takes 2 arguments, ```dt``` and ```state```. ```dt``` is the _delta time_, or the amount of time (in seconds) that has elapsed since the last game loop. ```state``` is what represents the state of the game; a collection of all the information you have about the game at the current time. It also provides methods for controlling your tank. 

### ```state``` API
First, let's look at the properties on ```state```:

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
11. ```score```: your current score
12. ```muzzle_speed```: the speed at which bullets are shot (constant, pixels per second)
13. ```radar```: a list of ```(x,y)``` pairs representing tanks scanned by your radar. 
14. ```obstacles```: a list of ```(x,y,r)``` objects, where ```x, y``` is the position of the obstacle and ```r``` is its radius

The only property that might not be self-explanatory is ```gun_heat```. Your gun must be completely cool to fire. When you shoot, your gun heats up according to how powerful the shot is.

Next, let's look at the methods provided to control your tank:

1. ```set_bearing(bearing)```: this sets the orientation of your turret immediately (radians)
2. ```fire(power)```: this makes a request to fire at the given power (temperature per second before cooldown; ```[0.1, 3.0]```)
3. ```exert(fx, fy)```: exert a force in the given x and y directions
4. ```aim_at(x, y)```: convenience method to turn your turret to aim at the given coordinate
5. ```closest()```: convenience method to get the closest scanned tank from ```radar```

### Considerations
A couple things necessitate a bit more detail. First, your radar isn't perfect; there's some noise in the signal, so the ```(x,y)``` readings of your opponent tanks aren't precise. Second, the amount of damage a bullet will do is a non-linear function of the power. Here's the function and its graph over the valid range of firepowers:

![Firepower function](https://s3.amazonaws.com/challenges.engineering/images/tanktastic-power.png "Firepower function")
