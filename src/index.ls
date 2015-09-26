
# Require

{ id, log, floor, abs, tau, sin, cos, div, v2, wrap } = require \std

pad-two = (str) -> if str.length < 2 then "0#str" else str
hex = (decimal) -> pad-two (floor decimal).to-string 16
rgb = ([r,g,b]) -> "##{hex r*255}#{hex g*255}#{hex b*255}"
normalise-rotation = (θ) -> if θ < 0 then tau - (-θ % tau) else θ % tau
rotation-to-color = (θ) ->
  if 0 < θ < tau
    floor (θ/tau) * colors.length
  else
    0

require \./global

{ FrameDriver } = require \./frame-driver
{ Blitter } = require \./blitter

Ease   = require \./ease
Timer  = require \./timer
Bullet = require \./bullet


# Debug

SHOW_EASING_TESTS = no
SHOW_TWEEN_BOXES = no


# Config

auto-travel-speed      = 100
max-speed              = 100
auto-fire-speed        = 0.08
dual-fire-separation   = 35
camera-drift-limit     = 200   # TODO: Make camera seek center gradually
flip-flop-time         = 0.2
rotation-history-limit = 200

colors =
  [1 0 0] [1 1 0] [0 1 0]
  [0 1 0] [0 1 1] [0 0 1]
  [0 0 1] [1 0 1] [1 0 0]


# Misc functions

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

lerp = (t, a, b) ->
  a + t * (b - a)

lerp-color = (t, start, end) ->
  [ (lerp t, start.0, end.0),
    (lerp t, start.1, end.1),
    (lerp t, start.2, end.2) ]


# Shared Gamestate

global.game-state =
  camera-zoom: 1
  camera-pos: [0 0]

  player:
    pos: [0 0]
    vel: [0 0]
    flipping: no
    flopping: yes
    color: 0
    rotation: 0

  input-state:
    up:    off
    down:  off
    left:  off
    right: off
    flip:  off
    flop:  on
    fire:  off
    mouse-x: 0
    mouse-y: 0

  timers:
    auto-fire-timer: Timer.create auto-fire-speed
    flip-flop-timer: Timer.create flip-flop-time, disabled: true

  shoot-alternate: no
  target-pos: [0 500]
  player-bullets: []


# Debug state

rotation-history = []

push-rotation-history = (n) ->
  rotation-history.push n
  if rotation-history.length >= rotation-history-limit
    rotation-history.shift!


# Helper classes

class Tween

  all-tweens = []

  ({ @from = 0, @to = 1, @in = 1, @with = Ease.Linear }) ->
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


#
# INIT
#

main-canvas  = new Blitter
frame-driver = new FrameDriver
debug-canvas = new Canvas

if SHOW_TWEEN_BOXES
  tween1 = new Tween from: 0, to: debug-canvas.canvas.width - 20, in: 1, with: Ease.Power3
  tween2 = new Tween from: 0, to: debug-canvas.canvas.width - 20, in: 1, with: Ease.Power2
  tween3 = new Tween from: 0, to: debug-canvas.canvas.width - 20, in: 1, with: Ease.Linear
  tween4 = new Tween from: 0, to: debug-canvas.canvas.width - 20, in: 1, with: Ease.PowerOut2
  tween5 = new Tween from: 0, to: debug-canvas.canvas.width - 20, in: 1, with: Ease.PowerOut3


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

  # Draw rotation graph
  let this = debug-canvas.ctx
    { width, height } = debug-canvas.canvas
    for d, x in rotation-history
      @fill-style = rgb colors[ rotation-to-color d ]
      @fill-rect x/rotation-history-limit * width, height - 10 - d * 10, 2, 2

    if SHOW_EASING_TESTS
      @fill-style = \white
      for i from 0 to width by 5
        @fill-rect i, height - 150 - 100 * Ease.Linear(i/width), 2, 2
      @fill-style = \red
      for i from 0 to width by 5
        @fill-rect i, height - 150 - 100 * Ease.Power2(i/width), 2, 2
      @fill-style = \orange
      for i from 0 to width by 5
        @fill-rect i, height - 150 - 100 * Ease.Power3(i/width), 2, 2
      @fill-style = \yellow
      for i from 0 to width by 5
        @fill-rect i, height - 150 - 100 * Ease.Power4(i/width), 2, 2
      @fill-style = \green
      for i from 0 to width by 5
        @fill-rect i, height - 150 - 100 * Ease.PowerOut2(i/width), 2, 2
      @fill-style = \cyan
      for i from 0 to width by 5
        @fill-rect i, height - 150 - 100 * Ease.PowerOut3(i/width), 2, 2
      @fill-style = \blue
      for i from 0 to width by 5
        @fill-rect i, height - 150 - 100 * Ease.PowerOut4(i/width), 2, 2

    if SHOW_TWEEN_BOXES
      @fill-style = \purple
      @fill-rect tween1.value, height - 150, 20, 20
      @fill-rect tween2.value, height - 170, 20, 20
      @fill-rect tween3.value, height - 190, 20, 20
      @fill-rect tween4.value, height - 210, 20, 20
      @fill-rect tween5.value, height - 230, 20, 20


  for bullet in @player-bullets
    Bullet.draw main-canvas, bullet


#
# UPDATE
#

update = (Δt, t) ->

  Tween.update-all Δt

  Timer.update-and-carry @timers.auto-fire-timer, Δt
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

  diamond = ([x, y]) ->
    if x == 0
      [x, y]
    else
      [x/2, y/2]

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

  # TODO: Work out if timer update feels better before or after
  Timer.update-and-stop @timers.flip-flop-timer, Δt

  # Check if in-progress flipflopping has ended
  if @timers.flip-flop-timer.elapsed
    if @player.flipping
      @player.color = wrap 0, colors.length - 1, @player.color + 1
      @player.flipping = no

    if @player.flopping
      @player.color = wrap 0, colors.length - 1, @player.color - 1
      @player.flopping = no

    #@player.rotation = @player.color * tau/3

  else
    # Update rotation based on timer
    p = Timer.get-progress @timers.flip-flop-timer
    #if @player.flipping
      #@player.rotation = @player.color * tau/3 + p * tau/3
    #if @player.flopping
      #@player.rotation = @player.color * tau/3 - p * tau/3

  # Consume inputs
  if @input-state.flip
    if not @player.flipping
      Timer.reset @timers.flip-flop-timer
    @player.flipping = yes
    @player.flopping = no
    @input-state.flip = no

  if @input-state.flop
    if not @player.flopping
      Timer.reset @timers.flip-flop-timer
    @player.flipping = no
    @player.flopping = yes
    @input-state.flop = no


  # Auto rotate

  @player.rotation = normalise-rotation -2*tau + 4*tau * @input-state.mouse-x


  push-rotation-history @player.rotation

  @player.color = rotation-to-color @player.rotation

  # Camera tracking

  #@camera-pos.0 = @player.pos.0
  @camera-pos.1 = @player.pos.1 + 200

  if @camera-pos.0 - @player.pos.0 > camera-drift-limit
    @camera-pos.0 -= (@camera-pos.0 - @player.pos.0 - camera-drift-limit)

  if @player.pos.0 - @camera-pos.0 > camera-drift-limit
    @camera-pos.0 += (@player.pos.0 - @camera-pos.0 - camera-drift-limit)


#
# Input
#

ENTER  = 13
SPACE  = 32
ESCAPE = 27
KEY_Z  = 90
KEY_X  = 88
KEY_C  = 67
LEFT   = 37
RIGHT  = 39
UP     = 38
DOWN   = 40

document.add-event-listener \mousemove, ({ pageX, pageY }) ->
  game-state.input-state.mouse-x = pageX / window.inner-width
  game-state.input-state.mouse-y = pageY / window.inner-height

document.add-event-listener \keydown, ({ which }:event) ->
  if event.shift-key then log which
  switch which
  | ESCAPE => frame-driver.toggle!
  | ENTER  => void
  | SPACE  => void
  | KEY_Z  => game-state.input-state.flip  = on
  | KEY_X  => game-state.input-state.fire  = on
  | KEY_C  => game-state.input-state.flop  = on
  | UP     => game-state.input-state.up    = on
  | LEFT   => game-state.input-state.left  = on
  | DOWN   => game-state.input-state.down  = on
  | RIGHT  => game-state.input-state.right = on
  | _  => return event
  event.prevent-default!
  return false

document.add-event-listener \keyup, ({ which }:event) ->
  if event.shift-key then log which
  switch which
  | SPACE  => void
  | KEY_Z  => game-state.input-state.flip  = off
  | KEY_X  => game-state.input-state.fire  = off
  | KEY_C  => game-state.input-state.flop  = off
  | UP     => game-state.input-state.up    = off
  | LEFT   => game-state.input-state.left  = off
  | DOWN   => game-state.input-state.down  = off
  | RIGHT  => game-state.input-state.right = off
  | _  => return event
  event.prevent-default!
  return false


# Init - default play-test-frame
frame-driver.on-frame render.bind game-state
frame-driver.on-tick update.bind game-state
frame-driver.start!

# Init - assign
main-canvas.install document.body
debug-canvas.install document.body

