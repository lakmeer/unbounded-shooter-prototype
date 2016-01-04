
# Require

{ id, log, rgb, sin, cos, tau } = require \std
{ rotation-to-color } = require \../common

{ Drawing } = require \./mixins
{ LimitedArray } = require \../limited-array


#
# Rotation History
#

export class RotationHistory implements Drawing

  (@ctx, @limit = 200) ->
    @history = new LimitedArray @limit

  push: (n) ->
    @history.push n

  draw: (width, height) ->
    for d, x in @history.items
      @box-at [x/@limit * width, height - 10 - d * 10], [2 2], rgb colors[ rotation-to-color d ]

