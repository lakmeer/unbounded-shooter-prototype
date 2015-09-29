
# Require

{ id, log, floor, abs, tau, sin, cos, div, v2 } = require \std
{ wrap, rgb, lerp } = require \std

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

diamond = ([x, y]) ->
  if x == 0
    [x, y]
  else
    [x/2, y/2]

color-barrel =
  draw: (cnv, pos, θ, r = 75, o = tau * 9/12, m = colors.length) ->
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


shoot = ->
  if game-state.fire-mode is FIRE_MODE_BLEND
    left  = game-state.player.pos `v2.add` [dual-fire-separation/-4 150]
    right = game-state.player.pos `v2.add` [dual-fire-separation/+4 150]
    game-state.player-bullets.push Bullet.create left, rgb colors[game-state.player.color - 1]
    game-state.player-bullets.push Bullet.create right, rgb colors[game-state.player.color + 1]

  else
    if game-state.shoot-alternate
      left = game-state.player.pos `v2.add` [dual-fire-separation/-2 150]
      game-state.player-bullets.push Bullet.create left, rgb colors[game-state.player.color]
    else
      right = game-state.player.pos `v2.add` [dual-fire-separation/+2 150]
      game-state.player-bullets.push Bullet.create right, rgb colors[game-state.player.color]
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
    flip-trigger-direction: TRIGGER_DIRECTION_STABLE
    flop-trigger-direction: TRIGGER_DIRECTION_STABLE

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

render = (Δt, t) ->
  p = Timer.get-progress @timers.flip-flop-timer

  player-color = rgb do
    if @player.flipping
      lerp-color p, colors[@player.color], colors[wrap 0, colors.length - 1, @player.color + 1]
    else if @player.flopping
      lerp-color p, colors[@player.color], colors[wrap 0, colors.length - 1, @player.color - 1]
    else
      colors[@player.color]

  sigil-pos = @player.pos `v2.add` [ 0 -8 ]

  main-canvas.clear!
  main-canvas.draw-origin!
  main-canvas.draw-local-grid!
  main-canvas.rect   @target-pos, [90 90], color: \blue
  main-canvas.uptri  @player.pos, [50 50], color: \#ccc
  main-canvas.circle sigil-pos, 10, color: player-color

  for bullet in @player-bullets
    Bullet.draw main-canvas, bullet


  # Debug rendering

  let this = debug-canvas.ctx

    { width, height } = debug-canvas.canvas

    debug-canvas.clear!
    color-barrel.draw debug-canvas, [width/2, 100], game-state.player.rotation
    @fill-style = rgb colors[game-state.player.color]
    @fill-rect width/2 - 2, 10, 4, 15

    for d, x in rotation-history
      @fill-style = rgb colors[ rotation-to-color d ]
      @fill-rect x/rotation-history-limit * width, height - 10 - d * 10, 2, 2

    @fill-style = \grey
    @fill-rect 20, height/2, 20, 50
    @fill-rect 50, height/2, 20, 50

    @fill-style = \white
    @fill-rect 20, height/2, 20, 50 * game-state.input-state.flip
    @fill-rect 50, height/2, 20, 50 * game-state.input-state.flop

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

    box = (i, s) ~>
      @fill-style = if not s then \lightgrey else \red
      @fill-rect width - 50, 40 + i * 40, 30, 30

    box 0, flipflopper.trigger-state.flip.ignore
    box 1, flipflopper.trigger-state.flop.ignore


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
    | BUTTON_FIRE  =>
      if @input-state.fire isnt value
        @input-state.fire = value

        if value
          shoot!
          if @fire-mode is FIRE_MODE_ALTERNATE
            Timer.reset @timers.auto-fire-timer, auto-fire-speed * if @fire-mode is FIRE_MODE_ALTERNATE then 1 else 2

    | MOVE_X => @input-state.x = value
    | MOVE_Y => @input-state.y = value

    | BUTTON_UP    => @input-state.up    = value
    | BUTTON_DOWN  => @input-state.down  = value
    | BUTTON_LEFT  => @input-state.left  = value
    | BUTTON_RIGHT => @input-state.right = value

    | TRIGGER_FLIP =>
      if @input-state.flip < value
        flipflopper.static-to-stage -1, value
      else if @input-state.flip > value
        flipflopper.static-to-stage -1, value
      @input-state.flip  = value

    | TRIGGER_FLOP =>
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

