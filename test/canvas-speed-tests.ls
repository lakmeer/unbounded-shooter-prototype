
{ test } = require \test

export canvas-speed-tests (main-canvas) ->

  test 'testing', ->
    log \testing

    # Helpers
    triangle = (w, h, x=10, y=10) ->
      @begin-path!
      @move-to x - w/2, y + h/2
      @line-to x + w/2, y + h/2
      @line-to x +  0,  y - h/2
      @line-to x - w/2, y + h/2
      @close-path!
      @fill!

    # Setup
    main-canvas.ctx.fill-style = \white
    triangle-sprite = document.create-element \canvas
    triangle-sprite.width = triangle-sprite.height = 20
    triangle-sprite.style.background = \magenta
    tctx = triangle-sprite.get-context \2d
    tctx.fill-style = \red
    triangle.call tctx, 20, 20
    document.body.append-child triangle-sprite

    big-triangle-sprite = document.create-element \canvas
    big-triangle-sprite.width = big-triangle-sprite.height = 60
    big-triangle-sprite.style.background = \magenta
    tctx = big-triangle-sprite.get-context \2d
    tctx.fill-style = \blue
    triangle.call tctx, 60, 60, 30, 30
    document.body.append-child big-triangle-sprite
    times = []

    # tests

    iterations = 10000
    advance = 12

    t = Date.now!
    for i from 0 to iterations
      triangle.call main-canvas.ctx, 20, 20, 0, advance
    times.push [ "FILL20", Date.now! - t ]
    advance += 30

    t = Date.now!
    for i from 0 to iterations
      main-canvas.ctx.draw-image triangle-sprite, 0, advance
    times.push [ "BLIT20", Date.now! - t ]
    advance += 70

    t = Date.now!
    for i from 0 to iterations
      triangle.call main-canvas.ctx, 60, 60, 0, advance
    times.push [ "FILL60", Date.now! - t ]
    advance += 70

    t = Date.now!
    for i from 0 to iterations
      main-canvas.ctx.draw-image big-triangle-sprite, 0, advance
    times.push [ "BLIT60", Date.now! - t ]
    advance += 70

    # Report

    #times.sort (a, b) -> b.1 - a.1
    most = 0
    most = times.reduce ((m, a) -> if m > a.1 then m else a.1), 0
    bar = 300

    main-canvas.ctx.font = "30px monospace"
    main-canvas.ctx.text-baseline = \middle

    for [label, time], i in times
      #if i is 0 then most := time
      main-canvas.ctx.fill-style = \cyan
      main-canvas.ctx.fill-rect 0, i * 40, bar * time/most, 30
      main-canvas.ctx.fill-style = \black
      main-canvas.ctx.fill-text label, 0, 15 + i * 40, bar * time/most
      main-canvas.ctx.fill-style = \magenta
      main-canvas.ctx.fill-text time, 10 + bar*time/most, 15 + i * 40

