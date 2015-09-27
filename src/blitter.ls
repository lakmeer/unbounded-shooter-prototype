
# Require

{ id, log, tau } = require \std


#
# Blitter
#

export class Blitter

  mode-to-operation = (mode) ->
    switch mode
    | MODE_NORMAL => \source-over
    | MODE_COLOR  => \hue
    | MODE_ADD    => \lighten
    | otherwise  => \source-over

  local-grid-size      = 500
  local-grid-fidelity  = 100
  camera-frustrum-size = [ 500, 750 ]
  camera-aspect        = 1.5

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

    #log window.inner-width, window.inner-height, @w, @h

    @wf = @w / camera-frustrum-size.0
    @hf = @h / camera-frustrum-size.1

  translate-pos: ([x, y]) ->
    [ @w/2 + (x - game-state.camera-pos.0) * @wf,
      @h/2 - (y - game-state.camera-pos.1) * @hf ]

  translate-size: ([w, h]) ->
    [ w * @wf, h * @hf ]

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

  rect: (pos, size, { color=\white, alpha=1, mode=MODE_NORMAL }) ->
    [x, y] = @translate-pos pos
    [w, h] = @translate-size size
    @ctx.global-composite-operation = mode-to-operation mode
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
    for i from ny - lgs til ny + lgs by local-grid-fidelity
      @_line [cx - lgs, i + local-grid-fidelity], [cx + lgs, i + local-grid-fidelity]
    @ctx.close-path!
    @ctx.stroke!

  install: (host) ->
    host.append-child @canvas

