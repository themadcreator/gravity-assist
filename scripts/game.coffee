---
---

GAME_STATE = {
  ships : []
}

class Vector
  @randomInGame : ->
    return new Vector(
      Sim.REPULSION_DIST + Math.random() * (GAME_WIDTH - 2 * Sim.REPULSION_DIST)
      Sim.REPULSION_DIST + Math.random() * (GAME_HEIGHT - 2 * Sim.REPULSION_DIST)
    )

  constructor : (@x = 0, @y = 0) ->

  clone : ->
    return new Vector(@x, @y)

  add : (v) ->
    @x += v.x
    @y += v.y
    return @

  sub : (v) ->
    @x -= v.x
    @y -= v.y
    return @

  scale : (s) ->
    @x *= s
    @y *= s
    return @

  distSq : (v) ->
    return (@x - v.x) * (@x - v.x) + (@y - v.y) * (@y - v.y)

class Ship
  @MAX_FUEL         : 100
  @FUEL_CONSUMPTION : 2
  @FUEL_REGEN       : 0.125

  constructor : (options = {}) ->
    _(@).extend(options).defaults({
      loc       : new Vector()
      vel       : new Vector()
      thrust    : new Vector()
      thrusting : false
      mass      : 10
      fuel      : Ship.MAX_FUEL
      color     : 'red'
      rotation  : 0
      rotating  : 0
    })

class Body
  constructor : (options = {}) ->
    _(@).extend(options).defaults({
      loc    : new Vector()
      vel    : new Vector()
      mass   : 100
      pinned : false
    })

class Game
  constructor : ->
    @state = {
      ships    : []
      bodies   : []
      missiles : []
    }

  addBody : (opts = {}) ->
    @state.bodies.push body = new Body(_.defaults(opts,
      loc    : Vector.randomInGame()
      mass   : 20 + 200 * Math.random()
      pinned : true
    ))
    return body

  addShip : (opts = {}) ->
    @state.ships.push ship = new Ship(_.defaults(opts,
      loc : Vector.randomInGame()
    ))
    return ship

class Controls
  @ROTATION_SPEED : 0.0625
  @THRUST         : 0.125
  @CHARACTER_MAPS : {
    right :
      left  : 37
      up    : 38
      down  : 40
      right : 39
    left :
      left  : 65
      up    : 87
      down  : 83
      right : 68
  }

  constructor : (@ship, @characterMap = @CHARACTER_MAPS.right) ->
    $(document).keydown(@keydown)
    $(document).keyup(@keyup)
    @down = {}

  keydown : (e) =>
    return if @down[e.which] # avoid autorepeat
    switch e.which
      when @characterMap.up
        @ship.thrust.y  = -Controls.THRUST # up
        @ship.thrusting = true
      when @characterMap.down
        @ship.thrust.y  =  Controls.THRUST # down
        @ship.thrusting = true
      when @characterMap.left  then @ship.rotating = -Controls.ROTATION_SPEED # left
      when @characterMap.right then @ship.rotating =  Controls.ROTATION_SPEED # right
      else return
    @down[e.which]  = true
    e.preventDefault()

  keyup : (e) =>
    switch e.which
      when @characterMap.up, @characterMap.down
          @ship.thrust.y  = 0
          @ship.thrusting = false
      when @characterMap.left  then @ship.rotating = 0 # left
      when @characterMap.right then @ship.rotating = 0 # right
      else return
    @down[e.which]  = false
    e.preventDefault()

class Sim
  @GRAVITY         : 0.001
  @REPULSION_DIST  : 40
  @REPULSION_FORCE : 0.01

  constructor : (selector, @game, @players) ->
    @canvas = $(selector)

  start : ->
    requestAnimationFrame(@loop)

  loop : =>
    @updateResources()
    @updatePhysics()
    @render()
    @start()

  updateResources : ->
    for ship in @game.state.ships
      if ship.thrusting and ship.fuel >= Ship.FUEL_CONSUMPTION
        ship.fuel -= Ship.FUEL_CONSUMPTION
      else if ship.fuel < Ship.MAX_FUEL
        ship.fuel += Ship.FUEL_REGEN
        ship.thrusting = false

  updatePhysics : ->
    for body in @game.state.bodies
      continue if body.pinned
      @applyPhysics(body, false)

    for ship in @game.state.ships
      @applyPhysics(ship, true)

  applyPhysics : (body, isShip = false) ->
    acc = new Vector()

    for other in @game.state.bodies
      continue if body is other
      # Add contribution of gravitational force to acceleration
      acc.add(other.loc.clone().sub(body.loc).scale(
        body.mass * other.mass / body.loc.distSq(other.loc) * Sim.GRAVITY
      ))

    # Repulse near edges
    if body.loc.x < Sim.REPULSION_DIST
      acc.x += Sim.REPULSION_FORCE * (Sim.REPULSION_DIST - body.loc.x)
    else if body.loc.x > GAME_WIDTH - Sim.REPULSION_DIST
      acc.x -= Sim.REPULSION_FORCE * (body.loc.x - (GAME_WIDTH - Sim.REPULSION_DIST))
    if body.loc.y < Sim.REPULSION_DIST
      acc.y += Sim.REPULSION_FORCE * (Sim.REPULSION_DIST - body.loc.y)
    else if body.loc.y > GAME_HEIGHT - Sim.REPULSION_DIST
      acc.y -= Sim.REPULSION_FORCE * (body.loc.y - (GAME_HEIGHT - Sim.REPULSION_DIST))

    if isShip
      # Apply rotation
      body.rotation += body.rotating

      # Apply thrust
      if body.thrusting and body.fuel > 0
        thrust = new Vector(
          -Math.sin(body.rotation) * Controls.THRUST
          Math.cos(body.rotation) * Controls.THRUST
        )
        acc.add(thrust)

    # Integrate
    body.vel.add(acc)
    body.loc.add(body.vel)

  render : ->
    ctx = @canvas[0].getContext('2d')
    ctx.clearRect(0, 0, GAME_WIDTH, GAME_HEIGHT);

    for body in @game.state.bodies
      ctx.beginPath()
      ctx.arc(body.loc.x, body.loc.y, body.mass * 0.1, 0, 2 * Math.PI, false)
      ctx.fillStyle = 'dodgerblue'
      ctx.fill()

    for ship in @game.state.ships
      ctx.save()
      ctx.translate(ship.loc.x, ship.loc.y)
      ctx.rotate(ship.rotation)
      ctx.beginPath()
      ctx.moveTo(-5, -5)
      ctx.lineTo( 0, 10)
      ctx.lineTo( 5, -5)
      ctx.lineTo( 0, -2)
      ctx.closePath()
      ctx.fillStyle = ship.color
      ctx.fill()
      ctx.restore()

    for player, i in @players
      ctx.fillStyle   = player.color
      ctx.strokeStyle = player.color
      ctx.fillRect(10, 10 + 15 * i, player.fuel * 2, 5)
      ctx.strokeRect(10, 10 + 15 * i, Ship.MAX_FUEL * 2, 5)


$(document).ready ->
  if not document.createElement('canvas')?.getContext?
    alert('Sorry, it looks like your browser does not support canvas!')
    return false

  game = new Game()
  _.times 5, -> game.addBody()
  _.times 3, -> game.addBody({mass : 30, pinned : false})

  new Controls(player1 = game.addShip({color : 'red'}),    Controls.CHARACTER_MAPS.left)
  new Controls(player2 = game.addShip({color : 'yellow'}), Controls.CHARACTER_MAPS.right)
  players = [player1, player2]
  new Sim('#game', game, players).start()




