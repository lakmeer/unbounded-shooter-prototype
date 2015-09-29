
#
# Debug visualiser's mixins
#

export Drawing =
  box-at: (pos, size, color) ->
    @ctx.fill-style = color
    @ctx.fill-rect pos.0 - size.0/2, pos.1 - size.1/2, size.0, size.1

  box-top: (pos, size, color) ->
    @ctx.fill-style = color
    @ctx.fill-rect pos.0 - size.0/2, pos.1, size.0, size.1

  circle: (pos, r, color) ->
    @ctx.fill-style = color
    @ctx.begin-path!
    @ctx.arc pos.0, pos.1, r, 0, tau
    @ctx.close-path!
    @ctx.fill!

