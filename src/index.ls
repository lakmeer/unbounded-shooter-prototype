
# Require

{ id, log, sin, cos, div, v2 } = require \std

{ FrameDriver } = require \./frame-driver

MODE_COLOR  = Symbol \color
MODE_NORMAL = Symbol \normal


# Helper Classes

class Blitter

  mode-to-operation = (mode) ->
    switch mode
    | MODE_NORMAL => \source-over
    | MODE_COLOR  => \hue
    | otherwise  => \source-over

  local-grid-size = 2000
  local-grid-fidelity = 250

  ->
    @canvas = document.create-element \canvas
    @ctx = @canvas.get-context \2d
    @set-size [ window.inner-width, window.inner-height ]

  set-size: (size) ->
    @w = @canvas.width  = size.0
    @h = @canvas.height = size.1

  translate-by-camera: ([x, y]) ->
    [ @w/2 + x - game-state.camera-pos.0, @h/2 - y + game-state.camera-pos.1 ]

  rect: (pos, size, { color=\white, alpha=1, mode=MODE_NORMAL }) ->
    @ctx.global-composite-operation = mode-to-operation mode
    [x, y] = @translate-by-camera pos
    [w, h] = size # TODO: Actual game units
    @ctx.global-alpha = alpha
    @ctx.fill-style = color
    @ctx.fill-rect x - w/2, y - h/2, w, h

  line: (start, end) ->
    @ctx.stroke-style = \white
    @ctx.begin-path!
    @_line @ctx, start, end
    @ctx.close-path!
    @ctx.stroke!

  _line: (start, end) ->
    [x1, y1] = @translate-by-camera start
    [x2, y2] = @translate-by-camera end
    @ctx.move-to x1, y1
    @ctx.line-to x2, y2

  uptri: (pos, size, { color=\white, alpha=1, mode=MODE_NORMAL }) ->
    @ctx.global-composite-operation = mode-to-operation mode
    @ctx.global-alpha = alpha
    @ctx.fill-style = color
    @ctx.begin-path!
    @_uptri pos, size
    @ctx.close-path!
    @ctx.fill!

  _uptri: (pos, size) ->
    [x, y] = @translate-by-camera pos
    [w, h] = size
    @ctx.move-to x - w/2, y + h/2
    @ctx.line-to x + w/2, y + h/2
    @ctx.line-to x +  0,  y - h/2
    @ctx.line-to x - w/2, y + h/2

  dntri: (pos, size, { color = \white, alpha = 1, mode = MODE_NORMAL }) ->
    @ctx.global-composite-operation = mode-to-operation mode
    @ctx.global-alpha = alpha
    @ctx.fill-style = color
    @ctx.begin-path!
    @_dntri pos, size
    @ctx.close-path!
    @ctx.fill!

  _dntri: (pos, size) ->
    [x, y] = @translate-by-camera pos
    [w, h] = size
    @ctx.move-to x - w/2, y - h/2
    @ctx.line-to x + w/2, y - h/2
    @ctx.line-to x +  0,  y + h/2
    @ctx.line-to x - w/2, y - h/2

  clear: ->
    @ctx.clear-rect 0, 0, @w, @h
    @ctx.global-alpha = 1
    @ctx.global-composite-operation = mode-to-operation MODE_NORMAL

  draw-origin: ->
    [cx, cy] = game-state.camera-pos
    @ctx.stroke-style = \#0f0
    @ctx.line-width = 2
    @ctx.begin-path!
    @_line [0, cy - 1000], [0, cy + 1000]
    @_line [cx - 1000, 0], [cx + 1000, 0]
    @ctx.close-path!
    @ctx.stroke!

  draw-local-grid: ->
    [cx, cy] = game-state.camera-pos
    nx = cx - cx % local-grid-fidelity
    ny = cy - cy % local-grid-fidelity
    lgs = local-grid-size/2
    @ctx.begin-path!
    @ctx.global-alpha = 0.4
    for i from nx - lgs to nx + lgs by local-grid-fidelity
      @_line [i, cy - lgs], [i, cy + lgs]
    for i from ny - lgs to ny + lgs by local-grid-fidelity
      @_line [cx - lgs, i], [cx + lgs, i]
    @ctx.close-path!
    @ctx.stroke!

  install: (host) ->
    host.append-child @canvas


# State

global.game-state =
  camera-pos: [0 0]
  player:
    pos: [0 0]
    vel: [0 0]
  target-pos: [0 500]
  player-bullets: []
  input-state:
    fire: off
    up: off
    down: off
    left: off
    right: off

auto-travel-speed    = 500
max-speed            = 500
auto-fire-speed      = 0.03
dual-fire-separation = 35
camera-drift-limit   = 500

auto-fire-timer =
  target: auto-fire-speed
  current: 0
  elapsed: no

shoot = ->
  left  = game-state.player.pos `v2.add` [dual-fire-separation/-2 150]
  right = game-state.player.pos `v2.add` [dual-fire-separation/+2 150]
  game-state.player-bullets.push Bullet.new left
  game-state.player-bullets.push Bullet.new right


# Flat Classes

Timer =
  update: (timer, Δt) ->
    if timer.current + Δt > timer.target
      timer.elapsed = yes
      timer.current = (timer.current + Δt) % timer.target
    else
      timer.current += Δt
      timer.elapsed = no

Bullet =
  new: (pos) ->
    pos: pos
    vel: [ 0 5000 ]
    size: [ 100 300 ]
    alpha: 0.6
    life: 1
    Δlife: 4

  draw: (canvas, { pos, size, alpha, life }) ->
    top-size = [ size.0, size.1 * 1/4 ]
    btm-size = [ size.0, size.1 * 3/4 ]
    top-pos = [ pos.0, pos.1 + size.1/4 ]
    btm-pos = [ pos.0, pos.1 - size.1/4 ]
    canvas.uptri top-pos, top-size, color: \red, alpha: life, mode: MODE_COLOR
    canvas.dntri btm-pos, btm-size, color: \red, alpha: life, mode: MODE_COLOR


# Init

frame-driver = new FrameDriver
main-canvas  = new Blitter

render = (Δt, t) ->
  main-canvas.clear!
  main-canvas.draw-origin!
  main-canvas.draw-local-grid!
  main-canvas.rect  @target-pos, [90 90], color: \blue
  main-canvas.uptri @player.pos, [50 50], color: \pink

  for bullet in @player-bullets
    Bullet.draw main-canvas, bullet

update = (Δt, t) ->
  Timer.update auto-fire-timer, Δt
  if auto-fire-timer.elapsed and @input-state.fire then shoot!

  @player-bullets .= filter (bullet) ->
    bullet.pos.1 += bullet.vel.1 * Δt
    bullet.life -= bullet.Δlife * Δt
    bullet.life > 0

  if @input-state.up    => @player.pos.1 += max-speed * Δt
  if @input-state.down  => @player.pos.1 -= max-speed * Δt
  if @input-state.left  => @player.pos.0 -= max-speed * Δt
  if @input-state.right => @player.pos.0 += max-speed * Δt


  @player.pos.1 += auto-travel-speed * Δt

  # Camera always tracks player, unlike other shooters where FoR is mostly static
  @camera-pos.1 = @player.pos.1 + 400

  if @camera-pos.0 - @player.pos.0 > camera-drift-limit
    @camera-pos.0 -= (@camera-pos.0 - @player.pos.0 - camera-drift-limit)

  if @player.pos.0 - @camera-pos.0 > camera-drift-limit
    @camera-pos.0 += (@player.pos.0 - @camera-pos.0 - camera-drift-limit)



# Debug Controls

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

