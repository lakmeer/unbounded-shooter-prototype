
# Require

{ id, log, floor, abs, tau, sin, cos, div, v2 } = require \std
{ wrap, rgb, lerp } = require \std

require \./global

{ FrameDriver } = require \./frame-driver
{ Blitter } = require \./blitter
{ Input }   = require \./input

Ease   = require \./ease
Timer  = require \./timer
Bullet = require \./bullet


# Helper classes

class Tween

  all-tweens = []

  ({ @from = 0, @to = 1, @in = 1, @with = Ease.Linear }) ->
    # log 'new Tween:', @from, @to
    @time = 0
    @range = @to - @from
    @elapsed = no
    all-tweens.push this

  update: (Δt) ->
    @time += Δt
    if @time >= @in
      @time = @in
      @elapsed = yes
    @value = @from + @range * @with @time/@in
    return not @elapsed

  @update-all = (Δt) ->
    all-tweens := all-tweens.filter (.update Δt)

  @Null =
    elapsed: no
    value: 0


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


class FlipFlopper

  stage-step = tau/6
  stage-to-rotation = (* stage-step)
  normalise-stage   = (s) -> if s < 0 then 6 - (-s % 6) else s % 6

  ({ @speed=1 }={}) ->
    @stage = 0
    @tween = Tween.Null
    @θ = 0

  tween-to-stage: (d) ->
    @stage += d
    @tween = new Tween do
      from: @θ,
      to: (stage-to-rotation @stage),
      in: @speed,
      with: Ease.PowerOut4

  static-to-stage: (d, t) ->

  update: (Δt) ->
    @θ = @tween.value
    if @tween.elapsed
      @stage = normalise-stage @stage
      @θ = normalise-rotation @θ



# Debug

SHOW_EASING_TESTS = no
SHOW_TWEEN_BOXES  = no


# Config

auto-travel-speed      = 100
max-speed              = 500
auto-fire-speed        = 0.08
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

normalise-rotation = (θ) ->
  if θ < 0 then tau - (-θ % tau) else θ % tau

lerp-color = (t, start, end) ->
  [ (lerp t, start.0, end.0),
    (lerp t, start.1, end.1),
    (lerp t, start.2, end.2) ]

rotation-to-color = (θ) ->
  θ = normalise-rotation θ
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
frame-driver = new FrameDriver
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

  main-canvas.clear!
  main-canvas.draw-origin!
  main-canvas.draw-local-grid!
  main-canvas.rect  @target-pos, [90 90], color: \blue
  main-canvas.uptri @player.pos, [50 50], color: player-color

  debug-canvas.clear!
  color-barrel.draw debug-canvas, [100 100], @player.rotation
  debug-canvas.ctx.fill-style = rgb colors[@player.color]
  debug-canvas.ctx.fill-rect 98, 10, 4, 15

  for bullet in @player-bullets
    Bullet.draw main-canvas, bullet


  # Debug rendering

  let this = debug-canvas.ctx

    { width, height } = debug-canvas.canvas

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


#
# UPDATE
#

update = (Δt, t) ->

  # Update timers

  Tween.update-all Δt
  flipflopper.update Δt
  Timer.update-and-carry @timers.auto-fire-timer, Δt
  input.update Δt  # Debug only - real trigger controller doesn't need timers


  # Consume input events

  while event = input.pending-events.shift!
    [ type, value ] = event

    switch type
    | BUTTON_FIRE  => @input-state.fire  = value
    | BUTTON_UP    => @input-state.up    = value
    | BUTTON_DOWN  => @input-state.down  = value
    | BUTTON_LEFT  => @input-state.left  = value
    | BUTTON_RIGHT => @input-state.right = value
    | TRIGGER_FLIP => @input-state.flip  = value
    | TRIGGER_FLOP => @input-state.flop  = value


  # Fire

  if @timers.auto-fire-timer.elapsed and @input-state.fire then shoot!

  @player-bullets .= filter (bullet) ->
    bullet.pos.1 += bullet.vel.1 * Δt
    bullet.life -= bullet.Δlife * Δt
    bullet.life > 0

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

  input-vel = [ left-to-right-vel, front-to-back-vel ]


  # Normalise input velocity or circle (fwd) or diamond (back)
  if input-vel.1 >= 0
    player-vel = (v2.norm input-vel) `v2.scale` max-speed
  else
    player-vel = (diamond input-vel) `v2.scale` max-speed

  # Apply input velocity
  @player.pos.0 += player-vel.0 * Δt
  @player.pos.1 += player-vel.1 * Δt


  #
  # Flipflopping
  #

  # Consume inputs
  if @input-state.flip-on
    flipflopper.tween-to-stage -1
    @player.flipping = yes
    @player.flopping = no
    @input-state.flip-on = off

  if @input-state.flop-on
    flipflopper.tween-to-stage +1
    @player.flipping = no
    @player.flopping = yes
    @input-state.flop-on = off

  if @input-state.flop-off
    @input-state.flop-off = off

  @player.rotation = flipflopper.θ
  @player.color = rotation-to-color @player.rotation

  push-rotation-history @player.rotation


  #
  # Camera tracking
  #

  #@camera-pos.0 = @player.pos.0
  @camera-pos.1 = @player.pos.1 + 200

  if @camera-pos.0 - @player.pos.0 > camera-drift-limit
    @camera-pos.0 -= (@camera-pos.0 - @player.pos.0 - camera-drift-limit)

  if @player.pos.0 - @camera-pos.0 > camera-drift-limit
    @camera-pos.0 += (@player.pos.0 - @camera-pos.0 - camera-drift-limit)



# Init - default play-test-frame
frame-driver.on-frame render.bind game-state
frame-driver.on-tick update.bind game-state
frame-driver.start!

global.frame-driver = frame-driver

# Init - assign
main-canvas.install document.body
debug-canvas.install document.body

