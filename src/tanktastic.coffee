root = exports ? this

RADIUS = 300
RADIUS2 = RADIUS * RADIUS
DBEARING_MAX = Math.PI / 4
MAX_SENSOR_NOISE = 28

class root.Game

  dt: 1/60
  dt2: 1/3600
  
  constructor: (seed, graphics) ->
    @seed = seed
    @tanks = []
    @bullets = []
    @lt = 0
    @a = 0
    @renderer = new Renderer(graphics) if graphics

  register_tank: (name, step, init = null) ->
    @tanks.push new Tank(name, step, init)

  init: -> tank.init @tanks.length - 1 for tank in @tanks

  step: ->
    tanks = @tanks.filter (tank) -> tank.life > 0
    @end_game() if tanks.length < 2
    @lt = new Date().getTime() unless @lt > 0
    now = new Date().getTime()
    dt = (now - @lt) / 1000.0
    @a += dt
    until @a < @dt
      tank.step @dt, @radar(tank, tanks) for tank in tanks
      @fire tanks
      @integrate tanks
      @resolve_collisions tanks
      @bullets = @bullets.filter (bullet) -> not bullet.dead
      @renderer.render(tanks, @bullets) if @renderer
      @a -= @dt
    @lt = now



  radar: (tank, tanks) -> @sensor t for t in tanks when t isnt tank

  sensor: (tank) ->
    x: tank.x - MAX_SENSOR_NOISE + Math.random() * MAX_SENSOR_NOISE
    y: tank.y - MAX_SENSOR_NOISE + Math.random() * MAX_SENSOR_NOISE

  integrate: (tanks) ->
    for bullet in @bullets
      bullet.x += bullet.vx * @dt
      bullet.y += bullet.vy * @dt

    for tank in tanks
      # adds drag
      tank.fx -= tank.vx * 0.03
      tank.fy -= tank.vy * 0.03
      # unit mass -> a = f/1 = f
      dx = Math.min(Math.max(tank.vx * @dt + 0.5 * tank.fx * @dt2, -5), 5)
      dy = Math.min(Math.max(tank.vy * @dt + 0.5 * tank.fy * @dt2, -5), 5)
      #dy = tank.vy * @dt + 0.5 * tank.fy * @dt2
      tank.vx = dx / @dt
      tank.vy = dy / @dt
      tank.x += dx
      tank.y += dy
      tank.bearing += tank.dbearing

  fire: (tanks) ->
    for tank in tanks
      if tank.gun_heat <= tank.fire_command
        bullet = new Bullet(tank, tank.fire_command, tank.x, tank.y, tank.fx, tank.fy)
        tank.gun_heat += tank.fire_command
        @bullets.push bullet
      else tank.gun_heat -= @dt

  resolve_collisions: (tanks) ->
    for i in [0..tanks.length-2]
      ti = tanks[i]
      for j in [i+1..tanks.length-1]
        tj = tanks[j]
        dx = tj.x - ti.x
        dy = tj.y - ti.y
        len2 = dx * dx + dy * dy
        if len2 <= (ti.r + tj.r) * (ti.r + tj.r)#ti.r * ti.r + tj.r * tj.r
          len = Math.sqrt len2
          dx /= len
          dy /= len
          dvx = tj.vx - ti.vx
          dvy = tj.vy - ti.vy
          impulse = -1 * (dvx * dx + dvy * dy)
          hlen = (ti.r + tj.r - len) # / 2
          ti.x -= dx * hlen 
          ti.y -= dy * hlen 
          tj.x += dx * hlen 
          tj.y += dy * hlen 
          ti.vx -= dx * impulse
          ti.vy -= dy * impulse
          tj.vx += dx * impulse
          tj.vy += dy * impulse


    for bullet in @bullets
      for tank in tanks
        unless bullet.tank is tank
          dx = bullet.x - tank.x
          dy = bullet.y - tank.y
          if dx * dx + dy * dy < tank.r * tank.r + bullet.r * bullet.r
            bullet.dead = true
            tank.life -= bullet.power
            tank.hit = true
            bullet.tank.score += bullet.power
            console.log tank.life
            break
      bullet.dead = true if bullet.x * bullet.x + bullet.y * bullet.y >= @r

  end_game: -> alert "End of game."


class Tank

  constructor: (@name, @step_target, @init_target) ->
    @r = 20
    rc = Math.random() * 0x88 | (Math.random() * 0x88) << 8 | (Math.random() * 0x88) << 16
    @color = "#" + rc.toString(16)
    @x = Math.random() * (RADIUS - 2 * @r)
    @y = Math.random() * (RADIUS - 2 * @r)
    @vx = @vy = @gun_heat = @score = 0
    @life = 100
    @bearing = Math.random() * 2 * Math.PI

  init: (num_tanks) -> @init_target num_tanks if @init_target

  step: (dt, radar) -> 
    @hit = false
    @fx = @fy = @dbearing = 0
    @step_target.apply(null, [dt, @to_state(radar)])

  to_state: (radar) ->
    @fx = @fy = @dbearing = 0.0
    tank = this
    x: @x
    y: @y
    radius: @r
    vx: @vx
    vy: @vy
    turn: (bearing) => tank.dbearing = Math.min(Math.max(-DBEARING_MAX, bearing), DBEARING_MAX)
    apply: (fx, fy) =>
      tank.fx += fx
      tank.fy += fy
    fire: (power) =>
      tank.fire_command = Math.min(Math.max(0.1, power.toFixed(1)), 5.0)
    bearing: @bearing
    radar: radar
    arena_radius: RADIUS
    gun_heat: @gun_heat
    life: @life
    score: @score

class Bullet
  constructor: (@tank, @power) ->
    i = Math.cos(@tank.bearing)
    j = Math.sin(@tank.bearing)
    @r = 1 + @power
    @x = @tank.x + i * (tank.r + @r - 6)
    @y = @tank.y + j * (tank.r + @r - 6)
    @vx = i * 200
    @vy = j * 200

class Renderer

  constructor: (@graphics) ->
  
  render: (tanks, bullets) ->
    @graphics.clear()
    @render_tank tank for tank in tanks
    @render_bullet bullet for bullet in bullets

  render_bullet: (bullet) ->
    @graphics.beginStroke bullet.tank.color
    @graphics.drawCircle bullet.x, bullet.y, bullet.r
    @graphics.endStroke()

  render_tank: (tank) ->
    @graphics.setStrokeStyle 2, "round"
    @graphics.beginStroke (if tank.hit then "#FF0000" else tank.color)
    @graphics.drawCircle tank.x, tank.y, tank.r
    cos = Math.cos tank.bearing
    sin = Math.sin tank.bearing
    @graphics.endStroke()
    @graphics.setStrokeStyle 2, "round"
    @graphics.beginStroke (if tank.hit then "#FF0000" else tank.color)
    @graphics.moveTo tank.x + -3 * cos - -3 * sin, tank.y + -3 * sin + -3 * cos
    @graphics.lineTo tank.x + -3 * cos - 3 * sin, tank.y + -3 * sin + 3 * cos
    @graphics.lineTo tank.x + (tank.r - 6) * cos - 3 * sin, tank.y + (tank.r - 6) * sin + 3 * cos
    @graphics.lineTo tank.x + (tank.r - 6) * cos - -3 * sin, tank.y + (tank.r - 6) * sin + -3 * cos
    @graphics.lineTo tank.x + -3 * cos - -3 * sin, tank.y + -3 * sin + -3 * cos
    @graphics.endStroke()

    

