root = exports ? this

WIDTH = 960
HEIGHT = 480

DBEARING_MAX = Math.PI / 4
MAX_SENSOR_NOISE = 3

class root.Game

	dt: 1/60
	dt2: 1/3600
	
	constructor: (seed, graphics) ->
		@seed = seed
		@tanks = []
		@bullets = []
		@obstacles = [new Obstacle(60, WIDTH / 2, HEIGHT/2)]
		@lt = 0
		@a = 0
		@renderer = new Renderer(graphics) if graphics

	register_tank: (name, step, init = null) ->
		@tanks.push new Tank(name, step, init)

	init: -> tank.init @tanks.length - 1 for tank in @tanks

	step: ->
		tanks = @tanks.filter (tank) -> tank.life > 0
		if tanks.length < 2
			return
			end_game()
		@lt = new Date().getTime() unless @lt > 0
		now = new Date().getTime()
		dt = (now - @lt) / 1000.0
		@a += dt
		tank.hit = false for tank in tanks
		until @a < @dt
			tank.step @dt, @radar(tank, tanks) for tank in tanks
			@fire tanks
			@integrate tanks
			@resolve_collisions tanks
			@bullets = @bullets.filter (bullet) -> not bullet.dead
			@a -= @dt
		@lt = now
		@renderer.render(tanks, @bullets, @obstacles) if @renderer



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
			tank.fx -= tank.vx * 0.4
			tank.fy -= tank.vy * 0.4
			# unit mass -> a = f/1 = f
			dx = Math.min(Math.max(tank.vx * @dt + 0.5 * tank.fx * @dt2, -1.5), 1.5)
			dy = Math.min(Math.max(tank.vy * @dt + 0.5 * tank.fy * @dt2, -1.5), 1.5)
			#dy = tank.vy * @dt + 0.5 * tank.fy * @dt2
			tank.vx = dx / @dt
			tank.vy = dy / @dt
			tank.x += dx
			tank.y += dy
			tank.bearing += tank.dbearing

	fire: (tanks) ->
		for tank in tanks
			if tank.gun_heat <= tank.fire_command
				bullet = new Bullet(tank, tank.fire_command)
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
				if len2 <= (ti.r + tj.r) * (ti.r + tj.r)
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

		for tank in tanks
			dx = 0
			dy = 0
			dx = 1 if tank.x <= tank.r
			dx = -1 if tank.x >= WIDTH - tank.r
			dy = 1 if tank.y <= tank.r
			dy = -1 if tank.y >= HEIGHT - tank.r
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


class Tank

	constructor: (@name, @step_target, @init_target) ->
		@r = 20
		rc = Math.random() * 0xBB | (Math.random() * 0xBB) << 8 | (Math.random() * 0xBB) << 16
		@color = "#" + rc.toString(16)
		@x = Math.random() * (WIDTH - 2 * @r)
		@y = Math.random() * (HEIGHT - 2 * @r)
		@vx = @vy = @gun_heat = @score = 0
		@life = 100
		@bearing = Math.random() * 2 * Math.PI

	init: (num_tanks) -> @init_target num_tanks if @init_target

	step: (dt, radar) -> 
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
		exert: (fx, fy) =>
			tank.fx += fx
			tank.fy += fy
		fire: (power) =>
			tank.fire_command = Math.min(Math.max(0.1, power.toFixed(1)), 5.0)
		bearing: @bearing
		radar: radar
		gun_heat: @gun_heat
		life: @life
		score: @score

class Bullet
	constructor: (@tank, @power) ->
		i = Math.cos(@tank.bearing)
		j = Math.sin(@tank.bearing)
		@r = 1 + @power
		@power = Math.pow(2, 1 + @power)
		@x = @tank.x + i * (tank.r + @r - 6)
		@y = @tank.y + j * (tank.r + @r - 6)
		@vx = i * 200
		@vy = j * 200

class Obstacle
	constructor: (@r, @x, @y) ->

class Renderer

	constructor: (@graphics) ->
	
	render: (tanks, bullets, obstacles) ->
		@graphics.clear()
		@render_tank tank for tank in tanks
		@render_bullet bullet for bullet in bullets
		@graphics.setStrokeStyle 4, "round"
		@graphics.beginStroke "#000000"
		@graphics.rect(0, 0, WIDTH, HEIGHT)
		@render_obstacle obstacle for obstacle in obstacles
	
	render_obstacle: (obstacle) ->
		@graphics.setStrokeStyle 4, "round"
		@graphics.beginStroke "#000000"
		@graphics.drawCircle obstacle.x, obstacle.y, obstacle.r
		@graphics.endStroke()

	render_bullet: (bullet) ->
		@graphics.beginStroke bullet.tank.color
		@graphics.drawCircle bullet.x, bullet.y, (2 + bullet.r) / 2
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

		

