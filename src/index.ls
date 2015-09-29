
# Require

{ id, log, floor, abs, tau, sin, cos, div, v2 } = require \std
{ wrap, rgb, lerp, rnd } = require \std

require \./global

{ FrameDriver } = require \./frame-driver
{ FlipFlopper } = require \./flipflopper
{ Blitter }     = require \./blitter
{ Input }       = require \./input
{ Tween }       = require \./tween

Ease   = require \./ease
Timer  = require \./timer
Bullet = require \./bullet

FIRE_MODE_ALTERNATE = Symbol \alternate
FIRE_MODE_BLEND     = Symbol \blend


# Helper classes

class Canvas

  ->
    @canvas = document.create-element \canvas
    @ctx = @canvas.get-context \2d
    @canvas.height = window.inner-height
    @canvas.width = window.inner-height / 1.5

  clear: ->
    @ctx.clear-rect 0, 0, @canvas.width, @canvas.height

  install: (host) ->
    host.append-child @canvas



# Debug

SHOW_EASING_TESTS = no
SHOW_TWEEN_BOXES  = no


# Config

auto-travel-speed      = 500
max-speed              = 500
auto-fire-speed        = 0.04
dual-fire-separation   = 35
camera-drift-limit     = 200   # TODO: Make camera seek center gradually
flip-flop-time         = 0.2
rotation-history-limit = 200

colors =
  [1 0 0] [1 1 0] [0 1 0]
  [0 1 0] [0 1 1] [0 0 1]
  [0 0 1] [1 0 1] [1 0 0]

flipflopper = new FlipFlopper speed: 0.2


# Misc functions

lerp-color = (t, start, end) ->
  [ (lerp t, start.0, end.0),
    (lerp t, start.1, end.1),
    (lerp t, start.2, end.2) ]

rotation-to-color = (θ) ->
  if 0 < θ < tau
    floor (θ/tau) * colors.length
  else
    0

rotation-to-sprite-index = (θ, frames) ->
  floor frames * (θ % (tau/3)) / (tau/3)

state-color = ->
  if it then \red else \lightgrey

diamond = ([x, y]) ->
  if x == 0
    [x, y]
  else
    [x/2, y/2]

box = (ctx, pos, size, color) ~>
  ctx.fill-style = color
  ctx.fill-rect pos.0 - size.0/2, pos.1 - size.1/2, size.0, size.1

box-top = (ctx, pos, size, color) ~>
  ctx.fill-style = color
  ctx.fill-rect pos.0 - size.0/2, pos.1, size.0, size.1

color-barrel =
  draw: (cnv, pos, θ, r = 60, o = tau * 9/12, m = colors.length) ->
    let this = cnv.ctx
      for color, i in colors
        @fill-style = rgb color
        @begin-path!
        @move-to pos.0, pos.1
        @arc pos.0, pos.1, r, -θ + tau/m*i + o, -θ + tau/m*(i+1) + o
        @close-path!
        @fill!
      @stroke-style = \white
      @begin-path!
      @move-to pos.0, pos.1
      @line-to pos.0 + r*sin(0), pos.1 - r*cos(0)
      @close-path!
      @stroke!

controller-state =
  draw: (cnv, [x, y], game-state) ->
    let this = cnv.ctx
      # Triggers
      box @, [x - 80, y - 20], trigger-size, \grey
      box @, [x + 80, y - 20], trigger-size, \grey
      box-top @, [x - 80, y - 52], [25 65 * game-state.input-state.flip], \white
      box-top @, [x + 80, y - 52], [25 65 * game-state.input-state.flop], \white

      # Trigger ignore state
      box @, [x - 80, y + 35], [25 25], state-color flipflopper.trigger-state.flip.ignore
      box @, [x + 80, y + 35], [25 25], state-color flipflopper.trigger-state.flop.ignore

      # Joystick range
      input-vel = [ game-state.input-state.x, game-state.input-state.y ]
      @begin-path!
      @arc x, y, 50, tau/2, tau
      @line-to x, y + 50
      @close-path!
      @stroke!

      # Joystick location
      @fill-style = \red
      @begin-path!
      @arc x + 50 * input-vel.0, y - 50 * input-vel.1, 6, 0, tau
      @close-path!
      @fill!

      # Special Buttons
      box @, [x - 65, y + 70], [55 25], if game-state.input-state.fire    then \yellow else \#333
      box @, [x + 0,  y + 70], [50 25], if game-state.input-state.super   then \yellow else \#333
      box @, [x + 65, y + 70], [55 25], if game-state.input-state.special then \yellow else \#333


shoot = ->
  if game-state.fire-mode is FIRE_MODE_BLEND
    left  = game-state.player.pos `v2.add` [dual-fire-separation/-2 150]
    mid   = game-state.player.pos `v2.add` [0 170]
    right = game-state.player.pos `v2.add` [dual-fire-separation/+2 150]
    game-state.player-bullets.push Bullet.create left,  2000, rgb colors[game-state.player.color - 1]
    game-state.player-bullets.push Bullet.create mid,   2000, rgb colors[game-state.player.color + 0]
    game-state.player-bullets.push Bullet.create right, 2000, rgb colors[game-state.player.color + 1]

  else
    if game-state.shoot-alternate
      left = game-state.player.pos `v2.add` [dual-fire-separation/-2 150]
      game-state.player-bullets.push Bullet.create left, 3000, rgb colors[game-state.player.color]
    else
      right = game-state.player.pos `v2.add` [dual-fire-separation/+2 150]
      game-state.player-bullets.push Bullet.create right, 3000, rgb colors[game-state.player.color]
    game-state.shoot-alternate = not game-state.shoot-alternate



# Shared Gamestate

global.game-state =
  camera-zoom: 1
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
  target-pos: [0 500]
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

    mouse-x: 0    # POINTERS
    mouse-y: 0


# Debug state

rotation-history = []

push-rotation-history = (n) ->
  rotation-history.push n
  if rotation-history.length >= rotation-history-limit
    rotation-history.shift!


#
# INIT
#

main-canvas  = new Blitter
debug-canvas = new Canvas
input        = new Input


#
# RENDER
#

Sprite = (src, [ width, height ], frames) ->
  image = new Image
  image.width  = width * frames
  image.height = height
  image.src    = src
  index: 0
  width: width
  height: height
  image: image
  frames: frames

player-sprite = Sprite \/assets/player-sprite.png, [ 100, 120 ], 24
player-sprite-size = [ 70 80 ]

trigger-size = [25 65]

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

  main-canvas.rect   @target-pos, [90 90], color: \blue

  main-canvas.sprite player-sprite, @player.pos, player-sprite-size
  len = 5 + rnd 50
  main-canvas.dntri @player.pos `v2.add` [0 -28 - len/2], [20 len], color: player-color

  for bullet in @player-bullets
    Bullet.draw main-canvas, bullet


  # Debug rendering

  let this = debug-canvas.ctx

    { width, height } = debug-canvas.canvas

    debug-canvas.clear!

    # Rotation barrel
    color-barrel.draw debug-canvas, [width/2, height/5], game-state.player.rotation
    box debug-canvas.ctx, [width/2, height/5 - 67], [8 15], rgb colors[game-state.player.color]

    # Controller state
    controller-state.draw debug-canvas, [width/2, height/2], game-state

    # Rotation history graph
    for d, x in rotation-history
      box debug-canvas.ctx, [x/rotation-history-limit * width, height - 10 - d * 10], [2 2], rgb colors[ rotation-to-color d ]

    # Misc
    if SHOW_EASING_TESTS
      @fill-style = \white
      for i from 0 to width by 5 => @fill-rect i, height - 150 - 100 * Ease.Linear(i/width), 2, 2
      @fill-style = \red
      for i from 0 to width by 5 => @fill-rect i, height - 150 - 100 * Ease.Power2(i/width), 2, 2
      @fill-style = \orange
      for i from 0 to width by 5 => @fill-rect i, height - 150 - 100 * Ease.Power3(i/width), 2, 2
      @fill-style = \yellow
      for i from 0 to width by 5 => @fill-rect i, height - 150 - 100 * Ease.Power4(i/width), 2, 2
      @fill-style = \green
      for i from 0 to width by 5 => @fill-rect i, height - 150 - 100 * Ease.PowerOut2(i/width), 2, 2
      @fill-style = \cyan
      for i from 0 to width by 5 => @fill-rect i, height - 150 - 100 * Ease.PowerOut3(i/width), 2, 2
      @fill-style = \blue
      for i from 0 to width by 5 => @fill-rect i, height - 150 - 100 * Ease.PowerOut4(i/width), 2, 2



#
# UPDATE
#

update = (Δt, t) ->

  # Update timers

  Tween.update-all Δt
  Timer.update-and-carry @timers.auto-fire-timer, Δt
  input.update Δt  # Debug only - real input controller doesn't need timers


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

    | INPUT_X => @input-state.x = value
    | INPUT_Y => @input-state.y = value

    | INPUT_PAUSE =>
      if value
        frame-driver.toggle!

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


  # Travel forward inexorably

  @player.pos.1 += auto-travel-speed * Δt
  @target-pos.1 += auto-travel-speed * Δt


  # Generate input velocity vector

  left-to-right-vel =
    if @input-state.left then -1
    else if @input-state.right then 1
    else 0

  front-to-back-vel =
    if @input-state.down then -1
    else if @input-state.up then 1
    else 0

  input-vel = [ @input-state.x, @input-state.y ]


  # Normalise input velocity or circle (fwd) or diamond (back)

  # if input-vel.1 >= 0
  #   player-vel = (v2.norm input-vel) `v2.scale` max-speed
  # else
  #   player-vel = (diamond input-vel) `v2.scale` max-speed

  player-vel = input-vel `v2.scale` max-speed


  # Apply input velocity to player

  @player.pos.0 += player-vel.0 * Δt
  @player.pos.1 += player-vel.1 * Δt


  #
  # Flipflopping
  #

  @player.rotation = flipflopper.rotation
  @player.color = rotation-to-color @player.rotation
  player-sprite.index = rotation-to-sprite-index @player.rotation, player-sprite.frames
  push-rotation-history @player.rotation


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

  @player-bullets .= filter (bullet) ->
    bullet.pos.1 += bullet.vel.1 * Δt
    bullet.life -= bullet.Δlife * Δt
    bullet.life > 0


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
debug-canvas.install document.body

