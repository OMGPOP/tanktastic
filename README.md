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

