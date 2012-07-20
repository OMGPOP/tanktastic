require "./seedrandom.js"
Bar = require "./node-progress.js"
t = require "./tanktastic.js"
fs = require "fs"

class Player
  constructor: (@name) ->
    @elo = 1000
    @wins = @losses = @ties = 0

  add_result: (result) ->
    if result < 0.5 then @losses++ else if result > 0.5 then @wins++ else @ties++


class Printer
  
  @add_cell: (len, value) -> "| " + @add_tabular(len, value.toString(), " ")
  @add_line: (len, cols, spacer="-") -> ("+" + @add_tabular(len + 1, "", spacer) for i in [1..cols]).join("") + "+\n"
  @add_tabular: (len, value, spacer) -> value + (spacer for i in [1..(len-value.length + 1)]).join ""
  
  @print: (players) ->
    output = "\n  Results:\n\n"
    results = []
    for k, v of players
      results.push v
    results.sort (a, b) -> b.wins - a.wins
    longest = 10
    for player, i in results
      output += "    " + (i+1) + ". " + player.name + "\n"
      longest = player.name.length if player.name.length > longest

    output += "\n"
    output += @add_line longest, 5
    output += @add_cell longest, "Tank"
    output += @add_cell longest, "Wins"
    output += @add_cell longest, "Losses"
    output += @add_cell longest, "Ties"
    output += @add_cell longest, "ELO"
    output += "|\n"
    output += @add_line longest, 5
    for player in results
      output += @add_cell longest, player.name
      output += @add_cell longest, player.wins
      output += @add_cell longest, player.losses
      output += @add_cell longest, player.ties
      output += @add_cell longest, Math.round(player.elo)
      output += "|\n"
    output += @add_line longest, 5
    console.log(output)


class Tournament
  constructor: (@tanks) ->
    @stats = {}
    @players = {}

  hash: (a, b) -> a.name + "-" + b.name

  run: ->
    n = @tanks.length
    @bar = new Bar("  Running Tournament [:bar] :percent :etas", { total:num_matches * ((n * n - n)/2), width:20 })
    for tank_i, i in @tanks[0..n-2]
      @players[tank_i.name] = new Player(tank_i.name) unless @players[tank_i.name]
      for tank_j, j in @tanks[i+1..n-1]
        @players[tank_j.name] = new Player(tank_j.name) unless @players[tank_j.name]
        @run_match tank_i, tank_j 
        @bar.tick()

  run_match: (ti, tj) ->
    shash = @hash ti, tj
    tip = @players[ti.name]
    tjp = @players[tj.name]
    @stats[shash] = {ties:tip.ties}
    @stats[shash][ti.name] = tip.wins
    @stats[shash][tj.name] = tjp.wins
    for i in [1..num_matches]
      game = new t.tanktastic.Game(seed + i)
      game.register_tank ti
      game.register_tank tj
      game.init()
      game.step() until game.is_complete()
      [winner, loser] = game.podium()
      dt = winner.life - loser.life
      result = Number((if dt is 0 then 0.5 else 0.5 + 0.5 * dt / Math.abs(dt)).toFixed(1))
      @players[winner.name].add_result result
      @players[loser.name].add_result 1 - result
      @update_elo @players[winner.name], @players[loser.name], result
      @bar.tick()
    @stats[shash].ties = tip.ties - @stats[shash].ties
    @stats[shash][ti.name] = tip.wins - @stats[shash][ti.name]
    @stats[shash][tj.name] = tjp.wins - @stats[shash][tj.name]

  update_elo: (a, b, result) ->
    ea = 1 / (1 + Math.pow(10, (b.elo - a.elo)/400))
    eb = 1 - ea
    k = 30 # this could be staggered but whatevs
    a.elo += k * (result - ea)
    b.elo += k * ((1 - result) - eb)


[name, path, tourney_dir, num_matches, seed] = process.argv
tanks = (require "./" + tourney_dir + tank for tank in fs.readdirSync(tourney_dir))

tournament = new Tournament tanks
tournament.run()
Printer.print(tournament.players)
