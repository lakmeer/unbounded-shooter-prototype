
# Require

{ id, log, rgb, sin, cos, tau } = require \std
{ rotation-to-color } = require \../common

{ Drawing } = require \./mixins


#
# Rotation History
#

export class RotationHistory implements Drawing

  (@ctx, @limit = 200) ->
    @history = []

  push: (n) ->
    @history.push n
    if @history.length >= @limit
      @history.shift!

  draw: (width, height) ->
    for d, x in @history
      @box-at [x/@limit * width, height - 10 - d * 10], [2 2], rgb colors[ rotation-to-color d ]

