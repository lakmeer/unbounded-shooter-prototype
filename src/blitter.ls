
export class Blitter

  mode-to-operation = (mode) ->
    switch mode
    | MODE_NORMAL => \source-over
    | MODE_COLOR  => \hue
    | MODE_ADD    => \lighten
    | otherwise  => \source-over

  local-grid-size    = 2000
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


