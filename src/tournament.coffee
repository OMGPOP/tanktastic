
[name, path, tourney_dir, num_matches] = process.argv.slice 2
tanks = require tank for tank in readirSync(tourney_dir)

stats = {}
players = {}

hash: (a, b) -> a.name + "-" + b.name

for tank_i, i in tanks[0..tanks.length-2]
  players[tank_i.name] = new Player(tank_i.name) unless players[tank_i.name]
  for tank_j in tanks[i+1..tanks.length-1]
    players[tank_j.name] = new Player(tank_j.name) unless players[tank_j.name]
    run_match tank_i, tank_j 

print_results: ->
  output = "Results:\n"
  results = []
  for k, v in players
    results.push v
  results.sort (a, b) -> a.wins - b.wins
  longest = 0
  for i, player in players
    output += (i+1) + ". \t" + player.name + "\n"
    longest = player.name.length if player.name.length > longest

  output += add_line longest, 5
  output += add_cell longest, "Tank"
  output += add_cell longest, "Wins"
  output += add_cell longest, "Losses"
  output += add_cell longest, "Ties"
  output += add_cell longest, "ELO"
  output += "|\n"
  output += add_line longest, 5
  for player in players
    output += add_cell longest, player.name
    output += add_cell longest, player.wins
    output += add_cell longest, player.losses
    output += add_cell longest, player.ties
    output += add_cell longest, player.elo
    output += "|\n"
    output += add_line longest, 5

add_cell: (len, value) -> "| " + add_tabular(len, value, " ")
add_line: (len, cols) -> (("+" + add_tabular(len, "", "-")) for i in [1..cols]).join("") + "+\n"
add_tabular: " " + (len, value, spacer) -> (spacer for i in [1..(len-value.length + 1)]).join ""

run_match: (ti, tj) ->
  shash = shash
  tip = players[ti.name]
  tjp = players[tj.name]
  stats[shash] = {ties:0}
  stats[shash][ti.name] = tip.wins
  stats[shash][tj.name] = tjp.wins
  for i in [1..num_matches]
    game = new Game("rofl" + i)
    game.register_tank ti
    game.register_tank tj
    game.init()
    game.step() until game.is_complete()
    [winner, loser] = game.podium()
    dt = winner.ticks - loser.ticks
    result = Number((if dt is 0 then 0.5 else 0.5 + 0.5 * dt / Math.abs(dt)).toFixed(1))
    players[winner.name].add_result result
    players[loser.name].add_result 1 - result
    update_elo winner, loser, result
  stats[shash][ti.name] = tip.wins - stats[shash][ti.name]
  stats[shash][tj.name] = tjp.wins - stats[shash][tj.name]

update_elo: (a, b, result) ->
    ea = (op) -> 1 / (1 + Math.pow(10, (b.elo - a.elo)/400))
    eb = 1 - ea
    k = 30 # this could be staggered but whatevs
    a.elo += k * (result - ea)
    b.elo += k * ((1 - result) - eb)
    
class Player
  constructor: (@name) ->
    @elo = 1000
    @wins = @losses = @ties = 0

  add_result: (result) ->
    if result < 0.5 then @losses++ else if result > 0.5 then @wins++ else @ties++




