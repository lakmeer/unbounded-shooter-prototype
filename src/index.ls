
# Require

{ id, log, sin, cos } = require \std

{ FrameDriver } = require \./frame-driver


# Helper Classes

class Blitter

  ->
    @canvas = document.create-element \canvas
    @ctx = @canvas.get-context \2d
    @set-size [ window.inner-width, window.inner-height ]

  set-size: (size) ->
    @w = @canvas.width  = size.0
    @h = @canvas.height = size.1

  translate-by-camera: ([x, y]) ->
    [ @w/2 + x - game-state.camera-pos.0, @h/2 - y + game-state.camera-pos.1 ]

  rect: (pos, size, color = \white) ->
    [x, y] = @translate-by-camera pos
    [w, h] = size # TODO: Actual game units
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

  uptri: (pos, size, color = \white) ->
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

  dntri: (pos, size, color = \white) ->
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

  draw-origin: ->
    [cx, cy] = game-state.camera-pos
    @ctx.stroke-style = \#0f0
    @ctx.line-width = 2
    @ctx.begin-path!
    @_line [0, cy - 1000], [0, cy + 1000]
    @_line [cx - 1000, 0], [cx + 1000, 0]
    @ctx.close-path!
    @ctx.stroke!

  install: (host) ->
    host.append-child @canvas


# State

global.game-state =
  camera-pos: [0 0]
  player-pos: [0 0]
  target-pos: [0 500]


# Init

frame-driver = new FrameDriver
main-canvas = new Blitter

render = (Δt, t) ->
  main-canvas.clear!
  main-canvas.draw-origin!
  main-canvas.rect  game-state.target-pos, [20 20], \blue
  main-canvas.uptri game-state.player-pos, [20 20], \red

update = (Δt, t) ->

  game-state.player-pos.0 = 100 * sin t
  game-state.player-pos.1 = 100 * t

  # Camera always tracks player, unlike other shooters where FoR is mostly static
  game-state.camera-pos.0 = game-state.player-pos.0
  game-state.camera-pos.1 = 100 * t


# Debug Controls

ENTER  = 13
SPACE  = 32
ESCAPE = 27

document.add-event-listener \keydown, ({ which }:event) ->
  switch which
  | ESCAPE => frame-driver.toggle!
  | ENTER  => server.add-local-player-at-next-open-slot!
  | _  => return event
  event.prevent-default!
  return false


# Init - default play-test-frame
frame-driver.on-frame render
frame-driver.on-tick update
frame-driver.start!

# Init - assign
main-canvas.install document.body

