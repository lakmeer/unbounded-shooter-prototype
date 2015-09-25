
# Require

{ id, log, floor, abs, tau, sin, cos, div, v2 } = require \std

pad-two = (str) -> if str.length < 2 then "0#str" else str
hex = (decimal) -> pad-two (floor decimal).to-string 16
rgb = ([r,g,b]) -> "##{hex r*255}#{hex g*255}#{hex b*255}"

require \./global

{ FrameDriver } = require \./frame-driver
{ Blitter } = require \./blitter

Timer  = require \./timer
Bullet = require \./bullet


# Config

auto-travel-speed    = 100
max-speed            = 100
auto-fire-speed      = 0.08
dual-fire-separation = 35
camera-drift-limit   = 200   # TODO: Make camera seek center gradually
flip-flop-time       = 0.2


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

  target-pos: [0 500]
  player-bullets: []
  input-state:
    up:    off
    down:  off
    left:  off
    right: off
    flip:  off
    flop:  on
    fire:  off
  timers:
    auto-fire-timer: Timer.create auto-fire-speed
    flip-flop-timer: Timer.create flip-flop-time, disabled: true
  shoot-alternate: no

colors =
  [1 0 0] [1 1 0] [0 1 0]
  [0 1 0] [0 1 1] [0 0 1]
  [0 0 1] [1 0 1] [1 0 0]


# Init

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

main-canvas  = new Blitter
frame-driver = new FrameDriver
debug-canvas = new Canvas

color-barrel =
  draw: (cnv, pos, θ, r = 75, o = tau * 9/12, m = colors.length) ->
    for color, i in colors
      cnv.ctx.fill-style = rgb color
      cnv.ctx.begin-path!
      cnv.ctx.move-to pos.0, pos.1
      cnv.ctx.arc pos.0, pos.1, r, -θ + tau/m*i + o, -θ + tau/m*(i+1) + o
      cnv.ctx.close-path!
      cnv.ctx.fill!
    cnv.ctx.stroke-style = \white
    cnv.ctx.begin-path!
    cnv.ctx.move-to pos.0, pos.1
    cnv.ctx.line-to pos.0 + r*sin(0), pos.1 - r*cos(0)
    cnv.ctx.close-path!
    cnv.ctx.stroke!


float-wrap = (min, max, n) -->
  if n >= max
    min + (n - min) % (max - min)
  else if n < min
    min - (n + min) % (max - min)
  else
    n

color-wrap = float-wrap 0, colors.length
tau-wrap = float-wrap 0, tau

rotation-to-color = (θ) ->
  color-wrap floor (tau-wrap θ) / (tau/colors.length)

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

{ wrap } = require \std

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


update = (Δt, t) ->
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

  @player.rotation = t
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

