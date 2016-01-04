
# Require

{ id, log, tau, rgb, sin, cos, v2 } = require \std
{ rotation-to-color } = require \../common

{ ColorWheel }          = require \./color-wheel
{ ControllerState }     = require \./controller-state
{ RotationHistory }     = require \./rotation-history
{ EasingDemonstration } = require \./easing-demonstration


#
# Debug Visualiser
#

export class DebugVis

  height = window.inner-height
  width  = window.inner-height / 1.5
  center = [width/2, height/2]

  (@flipflopper) ->

    # Canvas
    @canvas = document.create-element \canvas
    @ctx = @canvas.get-context \2d
    @w  = @canvas.width = width
    @h  = @canvas.height = height
    @cx = @w/2
    @cy = @h/2

    # Components
    @color-wheel   = new ColorWheel          @ctx, height/9
    @controller    = new ControllerState     @ctx, [300, 100], @flipflopper
    @rotation-hist = new RotationHistory     @ctx, 300
    @ease-demo     = new EasingDemonstration @ctx, [width, 100]

  clear: ->
    @ctx.clear-rect 0, 0, @w, @h

  render: ({ player }:game-state, Δt, t) ->
    @color-wheel.draw [@cx, height/5], player.rotation, player.color
    @controller.draw center, game-state

    if DEBUG_SHOW_EASING_TESTS
      @ease-demo.draw [0 height]
    else
      @rotation-hist.draw width, height

  push-rotation-history: (n) ->
    @rotation-hist.push n

  install: (host) ->
    host.append-child @canvas

