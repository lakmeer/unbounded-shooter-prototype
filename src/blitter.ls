
# Require

{ id, log, tau } = require \std


#
# Blitter
#

export class Blitter

  bg-aspect = 0.3125
  bg-scroll-speed = 20

  bg = new Image
  bg.src = \/assets/bg.jpg
  bg.onload = -> bg-aspect := bg.width / bg.height

  mode-to-operation = (mode) ->
    switch mode
    | MODE_NORMAL => \source-over
    | MODE_COLOR  => \hue
    | MODE_ADD    => \lighten
    | otherwise  => \source-over

  local-grid-size      = 1000
  local-grid-fidelity  = 100
  camera-aspect        = 1.5
  camera-frustrum-size = [ 1000, 1000 * camera-aspect ]

  ->
    @canvas = document.create-element \canvas
    @ctx = @canvas.get-context \2d
    @set-size [ window.inner-width, window.inner-height ]

  set-size: (size) ->
    if size.0 > size.1
      @w = @canvas.width  = size.1 / camera-aspect
      @h = @canvas.height = size.1
    else
      @w = @canvas.width  = size.0
      @h = @canvas.height = size.0 * camera-aspect

    @wf = @w / camera-frustrum-size.0
    @hf = @h / camera-frustrum-size.1

  translate-pos: ([x, y], z = game-state.camera-zoom) ->
    [ @w/2 + (x - game-state.camera-pos.0) * @wf * z,
      @h/2 - (y - game-state.camera-pos.1) * @hf * z]

  translate-size: ([w, h], z = game-state.camera-zoom) ->
    [ w * @wf * z, h * @hf * z ]

  circle: (pos, radius, { color=\white, alpha=1, mode=MODE_NORMAL }) ->
    [x, y] = @translate-pos pos
    [ r ]  = @translate-size [ radius ]  # TODO: This, but better
    @ctx.global-composite-operation = mode-to-operation mode
    @ctx.global-alpha = alpha
    @ctx.fill-style = color
    @ctx.begin-path!
    @ctx.arc x, y, r, 0, tau
    @ctx.close-path!
    @ctx.fill!

  stroke-circle: (pos, radius, { color=\white, alpha=1, mode=MODE_NORMAL }) ->
    [x, y] = @translate-pos pos
    [ r ]  = @translate-size [ radius ]  # TODO: This, but better
    @ctx.global-composite-operation = mode-to-operation mode
    @ctx.global-alpha = alpha
    @ctx.stroke-style = color
    @ctx.begin-path!
    @ctx.arc x, y, r, 0, tau
    @ctx.close-path!
    @ctx.stroke!

  rect: (pos, size, { color=\white, alpha=1, mode=MODE_NORMAL }) ->
    [x, y] = @translate-pos pos
    [w, h] = @translate-size size
    @ctx.global-composite-operation = mode-to-operation mode
    @ctx.global-alpha = alpha
    @ctx.fill-style = color
    @ctx.fill-rect x - w/2, y - h/2, w, h

  stroke-rect: (pos, size, { color=\white, alpha=1, mode=MODE_NORMAL }) ->
    [x, y] = @translate-pos pos
    [w, h] = @translate-size size
    @ctx.global-composite-operation = mode-to-operation mode
    @ctx.global-alpha = alpha
    @ctx.stroke-style = color
    @ctx.begin-path!
    @ctx.move-to x - w/2, y - w/2
    @ctx.line-to x + w/2, y - w/2
    @ctx.line-to x + w/2, y + h/2
    @ctx.line-to x - w/2, y + h/2
    @ctx.line-to x - w/2, y - w/2
    @ctx.close-path!
    @ctx.stroke!

  line: (start, end) ->
    @ctx.stroke-style = \white
    @ctx.begin-path!
    @_line @ctx, start, end
    @ctx.close-path!
    @ctx.stroke!

  _line: (start, end) ->
    [x1, y1] = @translate-pos start
    [x2, y2] = @translate-pos end
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
    [x, y] = @translate-pos pos
    [w, h] = @translate-size size
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
    [x, y] = @translate-pos pos
    [w, h] = @translate-size size
    @ctx.move-to x - w/2, y - h/2
    @ctx.line-to x + w/2, y - h/2
    @ctx.line-to x +  0,  y + h/2
    @ctx.line-to x - w/2, y - h/2

  clear: (t = 0) ->
    bg-height = @w / bg-aspect
    bg-offset = t * bg-scroll-speed % bg-height
    @ctx.clear-rect 0, 0, @w, @h
    @ctx.global-alpha = 1
    @ctx.global-composite-operation = mode-to-operation MODE_NORMAL
    #@ctx.draw-image bg, 0, bg-offset, @w, bg-height
    #@ctx.draw-image bg, 0, bg-offset - bg-height, @w, bg-height

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
    lgs-x = camera-frustrum-size.0/game-state.camera-zoom
    lgs-y = camera-frustrum-size.1/game-state.camera-zoom

    @stroke-rect game-state.camera-pos, camera-frustrum-size, color: \yellow

    @ctx.stroke-style = \#0f0
    @ctx.begin-path!
    @ctx.global-alpha = 0.4
    for i from nx - lgs-x to nx + lgs-x by local-grid-fidelity
      @_line [i, cy - lgs-y], [i, cy + lgs-y]
    for i from ny - lgs-y til ny + lgs-y by local-grid-fidelity
      @_line [cx - lgs-x, i + local-grid-fidelity], [cx + lgs-x, i + local-grid-fidelity]
    @ctx.close-path!
    @ctx.stroke!

  sprite: ({ width, height, image, index }, pos, size) ->
    [x, y] = @translate-pos pos
    [w, h] = @translate-size size
    @ctx.draw-image image, index * width, 0, width, height, x - w/2, y - h/2, w, h

  install: (host) ->
    host.append-child @canvas

