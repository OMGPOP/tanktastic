
class Game
	
	constructor: (@tanks, @dt) ->
		@bullets	= []
		@dt2 = @dt * @dt
		@r = 300

	init: -> tank.init @tanks.length - 1 for tank in @tanks

	step: ->
		tanks = @tanks.filter (tank) -> tank.life > 0
		end_game() if tanks.length < 2
		tank.step @dt, tank.to_state(), radar tank, tanks for tank in tanks
		fire tanks
		integrate tanks
		resolve_collisons tanks
		@bullets = @bullets.filter (bullet) -> not bullet.dead

	radar: (tank, tanks) ->	{x:t.x, y:t.y} for t in tanks when t isnt tank

	integrate: (tanks) ->
		for bullet in bullets
			bullet.x += bullet.vx * @dt
			bullet.y += bullet.vy * @dt

		for tank in tanks
			# adds drag
			tank.fx -= tank.vx * 0.03
			tank.fy -= tank.vy * 0.03
			# unit mass -> a = f/1 = f
			tank.vx += tank.fx * @dt
			tank.vy += tank.fy * @dt
			tank.x	+= tank.vx * @dt + tank.fx * @dt2
			tank.y	+= tank.vy * @dt + tank.fy * @dt2

	fire: (tanks) ->
		for tank in tanks
			if tank.gun_heat <= tank.fire_command
				bullet = new Bullet(tank, tank.fire_command, tank.x, tank.y, tank.fx, tank.fy)
				tank.gun_heat += tank.fire_command
				@bullets.push bullet
			else tank.gun_heat -= @dt

	resolve_collisions: ->
		for bullet in bullets
			for tank in @tanks
				unless bullet.tank is tank
					dx = bullet.x - tank.x
					dy = bullet.y - tank.y
					if dx * dx + dy * dy < tank.r * tank.r + bullet.r * bullet.r
						bullet.dead = true
						tank.life -= bullet.power
						bullet.tank.score += bullet.power
						break
			bullet.dead = true if bullet.x * bullet.x + bullet.y * bullet.y >= @r

	end_game: -> alert "End of game."


class Tank

	to_state: (opponents, r) ->
		@fx = @fy = 0.0
		x: @x
		y: @y
		radius: @r
		vx: @vx
		vy: @vy
		turn: (bearing) => @theta += bearing
		apply: (fx, fy) => 
			@fx += fx
			@fy += fy
		fire: (power) =>
			this.fire_command = Math.min(Math.max(0.1, power), 5.0)
		theta: @theta
		radar: opponents
		arena_radius: r
		gun_heat: @gun_heat
		life: @life
		score: @score

