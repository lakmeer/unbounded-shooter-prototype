
# Require

{ id, log, floor, sin, cos, div, v2 } = require \std

pad-two = (str) -> if str.length < 2 then "0#str" else str
hex = (decimal) -> pad-two (floor decimal).to-string 16
rgb = ([r,g,b]) -> "##{hex r*255}#{hex g*255}#{hex b*255}"

require \./global

{ FrameDriver } = require \./frame-driver
{ Blitter } = require \./blitter

Timer  = require \./timer
Bullet = require \./bullet


# Config

auto-travel-speed    = 500
max-speed            = 500
auto-fire-speed      = 0.08
dual-fire-separation = 35
camera-drift-limit   = 500
flip-flop-time       = 0.2


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
  target-pos: [0 500]
  player-bullets: []
  input-state:
    fire:  off
    up:    off
    down:  off
    left:  off
    right: off
  timers:
    auto-fire-timer: Timer.create auto-fire-speed
    flip-flop-timer: Timer.create flip-flop-time, disabled: true

colors =
  [1 0 0]
  [0 1 0]
  [0 0 1]


# Init

main-canvas  = new Blitter
frame-driver = new FrameDriver


shoot-alternate = no

shoot = ->
  if shoot-alternate
    left = game-state.player.pos `v2.add` [dual-fire-separation/-2 150]
    game-state.player-bullets.push Bullet.create left
  else
    right = game-state.player.pos `v2.add` [dual-fire-separation/+2 150]
    game-state.player-bullets.push Bullet.create right
  shoot-alternate := not shoot-alternate

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
      lerp-color p, colors[@player.color], colors[wrap 0, colors.length - 1, @player.color - 1]
    else if @player.flopping
      lerp-color p, colors[@player.color], colors[wrap 0, colors.length - 1, @player.color + 1]
    else
      colors[@player.color]

  main-canvas.clear!
  main-canvas.draw-origin!
  main-canvas.draw-local-grid!
  main-canvas.rect  @target-pos, [90 90], color: \blue
  main-canvas.uptri @player.pos, [50 50], color: player-color

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

  # Check if in-progress flipflopping has ended

  # TODO: Work out if timer update feels better before or after
  Timer.update-and-stop @timers.flip-flop-timer, Δt

  if @timers.flip-flop-timer.elapsed
    if @player.flipping
      @player.color = wrap 0, colors.length - 1, @player.color - 1
      @player.flipping = no

    if @player.flopping
      @player.color = wrap 0, colors.length - 1, @player.color + 1
      @player.flopping = no

  if @input-state.flip
    @player.flipping = yes
    @player.flopping = no
    Timer.reset @timers.flip-flop-timer

  if @input-state.flop
    @player.flipping = no
    @player.flopping = yes
    Timer.reset @timers.flip-flop-timer


  # Camera always tracks player, unlike other shooters where FoR is mostly static

  @camera-pos.1 = @player.pos.1 + 400

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

