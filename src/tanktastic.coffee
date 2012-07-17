
class Game
	
	constructor: (@tanks, @dt) ->
		@bullets	= []
		@dt2 = @dt * @dt
		@r = 300

	init: -> tank.init for tank in @tanks

	step: ->
		tank.step @dt, tank.state, radar for tank in @tanks
		fire()
		integrate()
		resolve_collisons()
		@tanks = @tanks.filter (tank) -> tank.life > 0
		@bullets = @bullets.filter (bullet) -> not bullet.dead
		end_game() if @tanks.length < 2

	integrate: ->
		for bullet in bullets
			bullet.x += bullet.vx * @dt
			bullet.y += bullet.vy * @dt

		for tank in @tanks
			# adds drag
			tank.fx -= tank.vx * 0.03
			tank.fy -= tank.vy * 0.03
			# unit mass -> a = f/1 = f
			tank.vx += tank.fx * @dt
			tank.vy += tank.fy * @dt
			tank.x	+= tank.vx * @dt + tank.fx * @dt2
			tank.y	+= tank.vy * @dt + tank.fy * @dt2

	fire: ->
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
					if dx * dx + dy * dy < tank.r + bullet.r
						bullet.dead = true
						tank.life -= bullet.power
						bullet.tank.score += bullet.power
						break
			bullet.dead = true if bullet.x * bullet.x + bullet.y * bullet.y >= @r

	end_game: -> alert "End of game."


class Tank

	to_state: (opponents, r) ->
		x: @x
		y: @y
		radius: @r
		vx: @vx
		vy: @vy
		fx: 0.0
		fy: 0.0
		theta: @theta
		radar: opponents
		arena_radius: r
		gun_heat: @gun_heat
		life: @life
		score: @score
