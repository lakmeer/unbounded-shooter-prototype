
# Require

{ id, log, sin, cos, div, v2 } = require \std

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


# Shared Gamestate

global.game-state =
  camera-zoom: 1
  camera-pos: [0 0]
  player:
    pos: [0 0]
    vel: [0 0]
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

render = (Δt, t) ->
  main-canvas.clear!
  main-canvas.draw-origin!
  main-canvas.draw-local-grid!
  main-canvas.rect  @target-pos, [90 90], color: \blue
  main-canvas.uptri @player.pos, [50 50], color: \pink

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


  # Normalise control input to unit circle

  left-to-right-vel =
    if @input-state.left then -1
    else if @input-state.right then 1
    else 0

  front-to-back-vel =
    if @input-state.down then -1
    else if @input-state.up then 1
    else 0

  input-vel  = [ left-to-right-vel, front-to-back-vel ]
  player-vel = (v2.norm input-vel) `v2.scale` max-speed

  if @input-state.up    => @player.pos.1 += player-vel.1 * Δt
  if @input-state.down  => @player.pos.1 += player-vel.1 * Δt
  if @input-state.left  => @player.pos.0 += player-vel.0 * Δt
  if @input-state.right => @player.pos.0 += player-vel.0 * Δt


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
  | KEY_Z  => game-state.input-state.fire = on
  | KEY_X  => void
  | KEY_C  => void
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
  | KEY_Z  => game-state.input-state.fire = off
  | KEY_X  => void
  | KEY_C  => void
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

