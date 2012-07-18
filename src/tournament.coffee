
[name, path, tourney_dir] = process.argv.slice 2
tanks = require tank for tank in readirSync(tourney_dir)


for tank_i, i in tanks[0..tanks.length-2]
  for tank_j in tanks[i+1..tanks.length-1]
    run_match tank_i, tank_j 

run_match: (ti, tj) ->
  for i in [1..5]
    game = new Game("rofl" + i)
    game.register_tank ti.name, ti.step, ti.init
    game.register_tank tj.name, tj.step, tj.init
    game.init()
    game.step() until game.is_complete()
    

