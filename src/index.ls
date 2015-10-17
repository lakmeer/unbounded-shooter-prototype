
#
# Require
#

{ id, log, floor, abs, tau, sin, cos, div, v2 } = require \std
{ wrap, rgb, lerp, rnd, random-range, delay } = require \std

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

shoot-by-rotation = ->
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

shoot-by-input = ->
  color = [
    if game-state.input-state.red   then 1 else 0
    if game-state.input-state.green then 1 else 0
    if game-state.input-state.blue  then 1 else 0
  ]

  if game-state.shoot-alternate
    left = game-state.player.pos `v2.add` [dual-fire-separation/-2 50]
    game-state.player-bullets.push new Bullet left, color
  else
    right = game-state.player.pos `v2.add` [dual-fire-separation/+2 50]
    game-state.player-bullets.push new Bullet right, color
  game-state.shoot-alternate = not game-state.shoot-alternate

get-fire-type-from-signal = ->
  switch it
  | INPUT_RED   => \red
  | INPUT_GREEN => \green
  | INPUT_BLUE  => \blue
  | otherwise => log "Can't recognise Radiant fire mode:", it

super-shoot = ->
  mid = game-state.player.pos `v2.add` [0 170]
  game-state.player-bullets.push new SuperBullet mid, [1 1 1]

spawn = ->
  targets = game-state.targets
  y = game-state.player.pos.1

  switch floor rnd 3
  | 0 =>
    targets.push new Target1 [-300 y + 600], [1 0 0]
    targets.push new Target2 [-150 y + 550], [1 1 0]
    targets.push new Target1 [0    y + 500], [0 1 0]
    targets.push new Target2 [150  y + 550], [0 1 1]
    targets.push new Target1 [300  y + 600], [0 0 1]
    targets.push new Target2 [0    y + 750], [1 0 1]

  | 1 =>
    color = [[1 0 0],[0 1 0],[0 0 1]][floor rnd 3]
    targets.push new Target1 [-300 y + 600], color
    targets.push new Target1 [-150 y + 550], color
    targets.push new Target1 [0    y + 500], color
    targets.push new Target1 [150  y + 550], color
    targets.push new Target1 [300  y + 600], color
    targets.push new Target1 [0    y + 750], color
    targets.push new Target1 [-300 y + 750], color
    targets.push new Target1 [-150 y + 700], color
    targets.push new Target1 [0    y + 650], color
    targets.push new Target1 [150  y + 700], color
    targets.push new Target1 [300  y + 750], color
    targets.push new Target1 [0    y + 900], color

  | 2 =>
    targets.push new Target2 [-300 y + 600], [1 1 0]
    targets.push new Target2 [-150 y + 550], [0 1 1]
    targets.push new Target2 [0    y + 500], [1 0 1]
    targets.push new Target2 [150  y + 550], [0 1 1]
    targets.push new Target2 [300  y + 600], [1 1 0]


#
# Master Gamestate
#

global.game-state =

  Δt: 0
  world-time: 0

  camera-zoom: 1
  camera-pos: [0 0]

  time-factor: 0.1

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
    red:   off
    green: off
    blue:  off
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

  # Update time

  @Δt = Δt * if EXP_STRICT_TIME_BINDING then @time-factor else 1
  @world-time += @Δt
  @system-time += Δt


  # Update timers

  Tween.update-all @Δt
  Timer.update-and-carry @timers.auto-fire-timer, @Δt
  input.update @Δt, @world-time  # Debug only - real input controller doesn't need timers


  # Consume input events

  while event = input.pending-events.shift!
    [ type, value ] = event

    switch type
    | INPUT_FIRE  =>
      if @input-state.fire isnt value
        @input-state.fire = value
        if value
          shoot-by-rotation!
          if @fire-mode is FIRE_MODE_ALTERNATE
            Timer.reset @timers.auto-fire-timer, auto-fire-speed * if @fire-mode is FIRE_MODE_ALTERNATE then 1 else 2

    | INPUT_RED, INPUT_BLUE, INPUT_GREEN =>
      color = get-fire-type-from-signal type
      if @input-state[color] isnt value
        @input-state[color] = value
        if value
          shoot-by-input!
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

  @player.pos.0 += player-vel.0 * @Δt

  if not EXP_STRICT_TIME_BINDING
    @player.pos.1 += player-vel.1 * @Δt


  # Travel forward inexorably

  if EXP_STRICT_TIME_BINDING
    @time-factor = 0.5 + normal-vec.1 / 2

  @player.pos.1 += auto-travel-speed * @Δt

  for target in @targets
    target.pos.1 += auto-travel-speed * @Δt


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

  if EXP_FIRE_MODE_IKARUGA
    if game-state.player.color % 3 is 1
      new-fire-mode = FIRE_MODE_BLEND
      fire-timer-factor = 2
    else
      new-fire-mode = FIRE_MODE_ALTERNATE
      fire-timer-factor = 1

    if @fire-mode isnt new-fire-mode
      if new-fire-mode is FIRE_MODE_ALTERNATE
        Timer.reset @timers.auto-fire-timer

    @timers.auto-fire-timer.target = auto-fire-speed * fire-timer-factor
    @fire-mode = new-fire-mode

    if new-fire-mode is FIRE_MODE_ALTERNATE
      if @timers.auto-fire-timer.elapsed and @input-state.fire
          shoot-by-rotation!

  if EXP_FIRE_MODE_RADIANT
    if @fire-mode is FIRE_MODE_ALTERNATE
      if @timers.auto-fire-timer.elapsed and (@input-state.red or @input-state.blue or @input-state.green)
        shoot-by-input!


  #
  # Move bullets
  #

  @player-bullets .= filter (.update @Δt).bind this

  # Check collisions
  color-sum = (color) ->
    color.0 + color.1 + color.2

  @targets .= filter (target, i) ~>
    target.update @Δt

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
        bullet.power -= damage

        if bullet.power <= 0
          bullet.life = 0

    target.health >= 0


  #
  # Camera tracking
  #

  @camera-pos.0 = @player.pos.0
  @camera-pos.1 = @player.pos.1

  if EXP_USE_LOOSE_CAMERA_TRACKING
    if @camera-pos.0 - @player.pos.0 > camera-drift-limit
      @camera-pos.0 -= (@camera-pos.0 - @player.pos.0 - camera-drift-limit)

    if @player.pos.0 - @camera-pos.0 > camera-drift-limit
      @camera-pos.0 += (@player.pos.0 - @camera-pos.0 - camera-drift-limit)


  #
  # Spawn enemies if necessary
  #

  if @targets.length is 0
    spawn!



  # Update backdrop

  main-canvas.update-bg @Δt


#
# INIT
#

global.frame-driver = new FrameDriver
frame-driver.on-frame render.bind game-state
frame-driver.on-tick update.bind game-state


# Init - assign

main-canvas.install document.body
debug-vis.install   document.body

frame-driver.start!

