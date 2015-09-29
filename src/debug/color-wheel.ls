
# Require

{ id, log, rgb, sin, cos, tau, v2 } = require \std

{ Drawing } = require \./mixins


#
# Color Wheel
#

export class ColorWheel implements Drawing

  o = tau * 9/12
  m = colors.length

  (@ctx, @r) ->

  draw: (pos, θ, player-color) ->
    for color, i in colors
      @ctx.fill-style = rgb color
      @ctx.begin-path!
      @ctx.move-to pos.0, pos.1
      @ctx.arc pos.0, pos.1, @r, -θ + tau/m*i + o, -θ + tau/m*(i+1) + o
      @ctx.close-path!
      @ctx.fill!

    @ctx.stroke-style = \white
    @ctx.begin-path!
    @ctx.move-to pos.0, pos.1
    @ctx.line-to pos.0 + @r*sin(0), pos.1 - @r*cos(0)
    @ctx.close-path!
    @ctx.stroke!

    @box-at pos `v2.add` [0 -67], [8 15], rgb colors[player-color]

