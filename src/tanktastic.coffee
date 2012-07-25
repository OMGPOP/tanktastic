root = exports ? this
root.tanktastic = {}

WIDTH = 960
HEIGHT = 480

MAX_DBEARING = Math.PI

MAX_ITERATIONS = 10000

MIN_FIRE_POWER = 0.1
MAX_FIRE_POWER = 3.0

MAX_SPEED  = 120.0 # pixels/second
MAX_SPEED2 = MAX_SPEED * MAX_SPEED

DRAG = 0.05
MUZZLE_SPEED = 400

LOG_10 = Math.log(10)
GAMMA = 1/3

limit = (x, min, max) -> Math.max(min, Math.min(x, max))
rand = (min, range) -> min + Math.random() * range

class root.tanktastic.Game

  dt: 1/60
  dt2: 1/3600
  
  constructor: (seed, graphics=null) ->
    Math.seedrandom seed
    @grng = new GaussRNG()
    @tanks = []
    @bullets = []
    @build_obstacles()
    @lt = 0
    @a = 0
    @iterations = 0
    @renderer = if graphics then new Renderer(graphics) else null

  is_rendered: -> @renderer isnt null
  is_complete: -> @iterations >= MAX_ITERATIONS or (tank for tank in @tanks when tank.life > 0).length < 2
  podium: -> 
    @tanks.slice().sort (a,b) -> 
      return 1 if a.ticks > b.ticks
      return -1 if a.ticks < b.ticks
      return 1 if a.life > b.life
      return -1 if a.life < b.life
      return 0

  build_obstacles: ->
    @obstacles = []
    num = 1 + Math.floor(Math.random() * 3)
    while @obstacles.length < num
      @obstacles.push new Obstacle(rand(30, 80), rand(WIDTH / 2 - 200, 400), rand(HEIGHT / 2 - 80, 160))

  register_tank: (tank) -> @tanks.push new Tank(tank.name, tank.step, tank.init)
  obstacle_state: -> {x:ob.x, y:ob.y, r:ob.r} for ob in @obstacles

  init: -> 
    @resolve_tank_obstacles @tanks
    tank.init @tanks.length - 1 for tank in @tanks

  step: (discrete=false) ->
    tanks = @tanks.filter (tank) -> tank.life > 0
    now = new Date().getTime()
    tank.hit = false for tank in tanks
    if (not discrete) and @is_rendered()
      @lt = now unless @lt > 0
      dt = (now - @lt) / 1000.0
      @a = Math.min @a + dt, 1.0
    else
      @a = @dt
    until @a < @dt
      tank.step @dt, @radar(tank, tanks), @obstacle_state() for tank in tanks
      @fire tanks
      @integrate tanks
      @resolve_collisions tanks
      @bullets = @bullets.filter (bullet) -> not bullet.dead
      @a -= @dt
    @lt = if discrete then 0 else now
    @iterations++
    @renderer.render(tanks, @bullets, @obstacles) if @is_rendered()

  radar: (tank, tanks) -> @sensor tank, t for t in tanks when t isnt tank

  sensor: (scanner, tank) ->
    dx = tank.x - scanner.x
    dy = tank.y - scanner.y
    dist = Math.max(Math.sqrt(dx * dx + dy * dy) - (tank.r + scanner.r), 1)
    sigma = GAMMA * Math.log(dist) / LOG_10
    x: tank.x + @grng.random(0, sigma)
    y: tank.y + @grng.random(0, sigma)

  render: -> @renderer.render(@tanks, @bullets, @obstacles)

  integrate: (tanks) ->
    for bullet in @bullets
      bullet.x += bullet.vx * @dt
      bullet.y += bullet.vy * @dt

    for tank in tanks
      # adds drag
      tank.fx -= tank.vx * DRAG
      tank.fy -= tank.vy * DRAG
      # unit mass -> a = f/1 = f
      tank.vx += tank.fx * @dt
      tank.vy += tank.fy * @dt
      speed = tank.vx * tank.vx + tank.vy * tank.vy
      if speed > MAX_SPEED2
        speed = Math.sqrt speed
        tank.vx *= MAX_SPEED / speed
        tank.vy *= MAX_SPEED / speed
      tank.x += tank.vx * @dt
      tank.y += tank.vy * @dt

  fire: (tanks) ->
    for tank in tanks
      if tank.gun_heat <= 0
        bullet = new Bullet(tank, tank.fire_command)
        tank.gun_heat += tank.fire_command
        @bullets.push bullet
      else tank.gun_heat = Math.max tank.gun_heat - @dt, 0

  resolve_collisions: (tanks) ->
    for i in [0..tanks.length-2]
      ti = tanks[i]
      for j in [i+1..tanks.length-1]
        tj = tanks[j]
        dx = tj.x - ti.x
        dy = tj.y - ti.y
        len2 = dx * dx + dy * dy
        if len2 <= (ti.r + tj.r) * (ti.r + tj.r)
          len = Math.sqrt len2
          dx /= len
          dy /= len
          dvx = tj.vx - ti.vx
          dvy = tj.vy - ti.vy
          impulse = -1 * (dvx * dx + dvy * dy)
          hlen = (ti.r + tj.r - len) / 2
          ti.x -= dx * hlen 
          ti.y -= dy * hlen 
          tj.x += dx * hlen 
          tj.y += dy * hlen 
          ti.vx -= dx * impulse
          ti.vy -= dy * impulse
          tj.vx += dx * impulse
          tj.vy += dy * impulse

    @resolve_tank_obstacles tanks

    for bullet in @bullets
      bullet.dead = true if bullet.x > WIDTH || bullet.x < 0 || bullet.y < 0 || bullet.y > HEIGHT || @does_collide(bullet)
      continue unless not bullet.dead
      for tank in tanks
        unless bullet.tank is tank
          dx = bullet.x - tank.x
          dy = bullet.y - tank.y
          if dx * dx + dy * dy <= (tank.r + bullet.r) * (tank.r + bullet.r)
            bullet.dead = true
            tank.life -= bullet.power
            tank.hit = true
            bullet.tank.score += bullet.power
            break

  does_collide: (bullet) -> 
    for obstacle in @obstacles
      dx = bullet.x - obstacle.x
      dy = bullet.y - obstacle.y
      return true if dx * dx + dy * dy <= Math.pow(bullet.r + obstacle.r, 2)
    return false

  end_game: -> alert "End of game."

  resolve_tank_obstacles: (tanks) ->
    for tank in tanks
      dx = 0
      dy = 0
      dx = tank.r - tank.x if tank.x <= tank.r
      dx = (WIDTH - tank.r) - tank.x if tank.x >= WIDTH - tank.r
      dy = tank.r - tank.y if tank.y <= tank.r
      dy = (HEIGHT - tank.r) - tank.y if tank.y >= HEIGHT - tank.r
      if dx
        tank.x += dx
        tank.vx *= -0.51
      if dy
        tank.y += dy
        tank.vy *= -0.51
      for obstacle in @obstacles
        dx = tank.x - obstacle.x
        dy = tank.y - obstacle.y
        len2 = dx * dx + dy * dy
        rsum = tank.r + obstacle.r
        if len2 <= rsum * rsum
          len = Math.sqrt len2
          dx /= len
          dy /= len
          dvx = dx * tank.vx
          dvy = dy * tank.vy
          tank.x += dx * (rsum - len)
          tank.y += dy * (rsum - len)
          impulse = -1.51 * (dvx * dx + dvy * dy)
          if impulse < 0
            tank.vx -= dx * impulse
            tank.vy -= dy * impulse



class Tank

  constructor: (@name, @step_target, @init_target) ->
    @ticks = 0 # track how many iterations we've been through
    @r = 20
    rc = Math.random() * 0xBB | (Math.random() * 0xBB) << 8 | (Math.random() * 0xBB) << 16
    @color = "#" + rc.toString(16)
    @color += "0" until @color.length > 6
    @x = Math.random() * (WIDTH - 2 * @r)
    @y = Math.random() * (HEIGHT - 2 * @r)
    @vx = @vy = @gun_heat = @score = 0
    @life = 100
    @bearing = Math.random() * 2 * Math.PI

  init: (num_tanks) -> @init_target num_tanks if @init_target

  step: (dt, radar, obstacles) -> 
    @fx = @fy = @dbearing = 0
    [state, controller] = @to_state radar, obstacles
    @step_target.apply(null, [dt, state, controller])
    @ticks++

  to_state: (radar, obstacles) ->
    @fx = @fy = @dbearing = 0.0
    tank = this
    controller = 
      set_bearing: (bearing) => tank.bearing = bearing
      exert: (fx, fy) =>
        tank.fx += fx
        tank.fy += fy
      fire: (power) => tank.fire_command = limit power, MIN_FIRE_POWER, MAX_FIRE_POWER
      aim_at: (x, y) => tank.bearing = Math.atan2(y - @y, x - @x)
    state = 
      x: @x
      y: @y
      w: WIDTH
      h: HEIGHT
      radius: @r
      vx: @vx
      vy: @vy
      bearing: @bearing
      radar: radar
      obstacles: obstacles
      gun_heat: @gun_heat
      life: @life
      muzzle_speed: MUZZLE_SPEED
      closest: -> 
        return radar[0] if radar.length is 1
        dists = radar.map ((op) -> {dist:Math.pow(op.x - tank.x, 2) + Math.pow(op.y - tank.y, 2), op:op})
        dists.sort((a, b) -> a.dist - b.dist)[0].op
    [state, controller]

class Bullet
  constructor: (@tank, @power) ->
    i = Math.cos @tank.bearing
    j = Math.sin @tank.bearing
    @r = 2 + @power
    @power = Math.exp(@power) - 1/3#Math.pow(2,@power + 1) / 2 #Math.pow(1 + @power / 2, 2) * Math.sqrt(@power) 
    @x = @tank.x + i * (tank.r + @r - 6)
    @y = @tank.y + j * (tank.r + @r - 6)
    @vx = i * MUZZLE_SPEED
    @vy = j * MUZZLE_SPEED

class Obstacle
  constructor: (@r, @x, @y) ->

class Renderer

  constructor: (@graphics) ->
  
  render: (tanks, bullets, obstacles) ->
    @graphics.clear()
    @render_obstacle obstacle for obstacle in obstacles
    @render_tank tank for tank in tanks
    @render_bullet bullet for bullet in bullets
    @graphics.setStrokeStyle 4, "round"
    @graphics.beginStroke "#000000"
    @graphics.rect(0, 0, WIDTH, HEIGHT)
    @graphics.endStroke()
  
  render_obstacle: (obstacle) ->
    @graphics.setStrokeStyle 4, "round"
    @graphics.beginStroke "#000000"
    @graphics.drawCircle obstacle.x, obstacle.y, obstacle.r
    @graphics.endStroke()

  render_bullet: (bullet) ->
    @graphics.beginFill bullet.tank.color
    @graphics.drawCircle bullet.x, bullet.y, (2 + bullet.r) / 2
    @graphics.endFill()

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
    @render_life tank

  render_life: (tank) ->
    @graphics.beginFill("#FFFFFF")
    @graphics.rect(tank.x + 5, tank.y - 22, 22, 8)
    @graphics.endFill()
    @graphics.setStrokeStyle 1, "round"
    @graphics.beginStroke tank.color
    @graphics.rect(tank.x + 5, tank.y - 22, 22, 8)
    @graphics.endStroke()
    @graphics.beginFill tank.color
    life = Math.max tank.life, 0
    @graphics.rect(tank.x + 7, tank.y - 20, 18 * life / 100, 4)
    @graphics.endFill()

class GaussRNG
  constructor: ->
    @v1 = @v2 = @s = @phase = 0

  random: (mu, sigma) ->
    if @phase is 0
      loop
        @v1 = 2 * Math.random() - 1
        @v2 = 2 * Math.random() - 1
        @s = @v1 * @v1 + @v2 * @v2
        break unless @s >= 1 or @s is 0
      x = @v1 * Math.sqrt(-2 * Math.log(@s) / @s)
    else
      x = @v2 * Math.sqrt(-2 * Math.log(@s) / @s)
    @phase = 1 - @phase
    return mu + sigma * x



