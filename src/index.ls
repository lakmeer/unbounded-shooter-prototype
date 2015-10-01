
#
# Require
#

{ id, log, floor, abs, tau, sin, cos, div, v2 } = require \std
{ wrap, rgb, lerp, rnd, random-range } = require \std

require \./global

{ FrameDriver } = require \./frame-driver
{ FlipFlopper } = require \./flipflopper
{ DebugVis }    = require \./debug
{ Blitter }     = require \./blitter
{ Sprite }      = require \./sprite
{ Input }       = require \./input
{ Tween }       = require \./tween
{ Bullet, BlendBullet, SuperBullet } = require \./bullet
{ Target1, Target2, Target3 } = require \./target

Ease   = require \./ease
Timer  = require \./timer

{ lerp-color, diamond, rotation-to-color, rotation-to-sprite-index } = require \./common


#
# Config
#

auto-travel-speed      = 500
max-speed              = 500
auto-fire-speed        = 0.04
dual-fire-separation   = 35
camera-drift-limit     = 200   # TODO: Make camera seek center gradually
flip-flop-time         = 0.2
rotation-history-limit = 200
hit-radius             = 25


#
# INIT
#

main-canvas  = new Blitter
input        = new Input
flipflopper  = new FlipFlopper speed: 0.2
debug-vis    = new DebugVis flipflopper


# Misc functions

shoot = ->
  if game-state.fire-mode is FIRE_MODE_BLEND
    mid = game-state.player.pos `v2.add` [0 170]
    game-state.player-bullets.push new BlendBullet mid, colors[game-state.player.color + 0]

  else
    if game-state.shoot-alternate
      left = game-state.player.pos `v2.add` [dual-fire-separation/-2 50]
      game-state.player-bullets.push new Bullet left, colors[game-state.player.color]
    else
      right = game-state.player.pos `v2.add` [dual-fire-separation/+2 50]
      game-state.player-bullets.push new Bullet right, colors[game-state.player.color]
    game-state.shoot-alternate = not game-state.shoot-alternate

super-shoot = ->
  mid = game-state.player.pos `v2.add` [0 170]
  game-state.player-bullets.push new SuperBullet mid, [1 1 1]


# Shared Gamestate

global.game-state =
  camera-zoom: 0.7
  camera-pos: [0 0]

  player:
    pos: [0 0]
    vel: [0 0]
    flipping: no
    flopping: no
    color: 0
    rotation: 0

  timers:
    auto-fire-timer: Timer.create auto-fire-speed
    flip-flop-timer: Timer.create flip-flop-time, disabled: true

  fire-mode: FIRE_MODE_ALTERNATE
  shoot-alternate: no
  fire-render-alternate: no
  player-bullets: []

  input-state:
    up:    off    # BUTTONS
    down:  off
    left:  off
    right: off
    fire:  off
    pause: off
    flip: 0       # TRIGGERS
    flop: 0
    x: 0          # JOYSTICKS
    y: 0
    raw-x: 0      # JOYSTICK DEBUG
    raw-y: 0
    mouse-x: 0    # POINTERS
    mouse-y: 0

  targets: []


game-state.targets.push new Target1 [-300 600], [1 0 0], 100
game-state.targets.push new Target2 [-150 550], [1 1 0], 100
game-state.targets.push new Target1 [0 500],    [0 1 0], 100
game-state.targets.push new Target2 [150 550],  [0 1 1], 100
game-state.targets.push new Target1 [300 600],  [0 0 1], 100
game-state.targets.push new Target2 [0 750],    [1 0 1], 100



#
# RENDER
#

player-sprite = new Sprite \/assets/player-sprite.png, [ 100, 120 ], 24
player-sprite-size = [ 70 80 ]

render = (Δt, t) ->
  p = Timer.get-progress @timers.flip-flop-timer

  player-color = rgb do
    if @player.flipping
      lerp-color p, colors[@player.color], colors[wrap 0, colors.length - 1, @player.color + 1]
    else if @player.flopping
      lerp-color p, colors[@player.color], colors[wrap 0, colors.length - 1, @player.color - 1]
    else
      colors[@player.color]

  main-canvas.clear t
  main-canvas.draw-origin!
  main-canvas.draw-local-grid!

  for target in @targets
    target.draw main-canvas

  len = random-range 5, 50
  main-canvas.rect  @player.pos `v2.add` [0 -500], [ 3, 1000 ], color: player-color
  main-canvas.sprite player-sprite, @player.pos, player-sprite-size
  main-canvas.dntri @player.pos `v2.add` [0 -28 - len/2], [20 len], color: player-color

  for bullet in @player-bullets
    bullet.draw main-canvas
    #main-canvas.circle bullet.pos, hit-radius, color: rgb colors[@player.color]
    main-canvas.stroke-circle bullet.pos, bullet.radius, color: \white


  # Debug rendering
  debug-vis.clear!
  debug-vis.render game-state, flipflopper, Δt, t


#
# UPDATE
#

update = (Δt, t) ->

  # Update timers

  Tween.update-all Δt
  Timer.update-and-carry @timers.auto-fire-timer, Δt
  input.update Δt, t  # Debug only - real input controller doesn't need timers


  # Consume input events

  while event = input.pending-events.shift!
    [ type, value ] = event

    switch type
    | INPUT_FIRE  =>
      if @input-state.fire isnt value
        @input-state.fire = value
        if value
          shoot!
          if @fire-mode is FIRE_MODE_ALTERNATE
            Timer.reset @timers.auto-fire-timer, auto-fire-speed * if @fire-mode is FIRE_MODE_ALTERNATE then 1 else 2

    #| INPUT_X => @input-state.x = value
    #| INPUT_Y => @input-state.y = value

    | INPUT_RAW_X => @input-state.raw-x = value
    | INPUT_RAW_Y => @input-state.raw-y = value

    | INPUT_PAUSE =>
      if value
        frame-driver.toggle!

    | INPUT_SUPER =>
      if value
        super-shoot!

    | INPUT_FLIP =>
      if @input-state.flip < value
        flipflopper.static-to-stage -1, value
      else if @input-state.flip > value
        flipflopper.static-to-stage -1, value
      @input-state.flip  = value

    | INPUT_FLOP =>
      if @input-state.flop < value
        flipflopper.static-to-stage 1, value
      else if @input-state.flop > value
        flipflopper.static-to-stage 1, value
      @input-state.flop  = value


  # Normalise X/Y input

  input-vec = [ @input-state.raw-x, @input-state.raw-y ]

  normal-vec =
    if input-vec.1 > 0
      v2.norm input-vec
    else
      θ = Math.atan2 -@input-state.raw-y, Math.abs @input-state.raw-x
      α = tau/2 - tau/8
      mag = sin(α) / sin(α - θ)
      (v2.norm input-vec) `v2.scale` mag

  @input-state.x = normal-vec.0
  @input-state.y = normal-vec.1

  player-vel = normal-vec `v2.scale` max-speed

  @player.pos.0 += player-vel.0 * Δt
  @player.pos.1 += player-vel.1 * Δt


  # Travel forward inexorably

  @player.pos.1 += auto-travel-speed * Δt

  for target in @targets
    target.pos.1 += auto-travel-speed * Δt


  #
  # Flipflopping
  #

  @player.rotation = flipflopper.rotation
  @player.color = rotation-to-color @player.rotation
  player-sprite.index = rotation-to-sprite-index @player.rotation, player-sprite.frames

  debug-vis.push-rotation-history @player.rotation


  #
  # Firing
  #

  if game-state.player.color % 3 is 1
    new-fire-mode = FIRE_MODE_BLEND
    fire-timer-factor = 2
  else
    new-fire-mode = FIRE_MODE_ALTERNATE
    fire-timer-factor = 1

  @timers.auto-fire-timer.target = auto-fire-speed * fire-timer-factor

  if new-fire-mode is FIRE_MODE_ALTERNATE
    if @timers.auto-fire-timer.elapsed and @input-state.fire
      shoot!

  if @fire-mode isnt new-fire-mode
    if new-fire-mode is FIRE_MODE_ALTERNATE
      Timer.reset @timers.auto-fire-timer

  @fire-mode = new-fire-mode


  #
  # Move bullets
  #

  @player-bullets .= filter (.update Δt)


  # Check collisions
  color-sum = (color) ->
    color.0 + color.1 + color.2

  @targets .= filter (target, i) ~>
    for bullet in @player-bullets
      dist = (target.pos `v2.dist` bullet.pos)
      if dist <= (target.radius + bullet.radius)

        target-value = color-sum target.color
        bullet-value = color-sum bullet.color

        additive-bonus = color-sum [
          target.color.0 * bullet.color.0,
          target.color.1 * bullet.color.1,
          target.color.2 * bullet.color.2
        ]

        damage-bonus = additive-bonus/target-value * bullet-value
        damage = (1 + damage-bonus) * bullet.power

        target.damage damage
        bullet.life = 0

    target.health >= 0


  #
  # Camera tracking
  #

  #@camera-pos.0 = @player.pos.0
  @camera-pos.1 = @player.pos.1 + 200

  if @camera-pos.0 - @player.pos.0 > camera-drift-limit
    @camera-pos.0 -= (@camera-pos.0 - @player.pos.0 - camera-drift-limit)

  if @player.pos.0 - @camera-pos.0 > camera-drift-limit
    @camera-pos.0 += (@player.pos.0 - @camera-pos.0 - camera-drift-limit)



#
# INIT
#

global.frame-driver = new FrameDriver
frame-driver.on-frame render.bind game-state
frame-driver.on-tick update.bind game-state
frame-driver.start!


# Init - assign

main-canvas.install  document.body
debug-vis.install document.body

