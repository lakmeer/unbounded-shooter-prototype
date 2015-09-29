
# Require

{ id, log, rgb, sin, cos, tau } = require \std

{ Drawing } = require \./mixins


#
# Easing Demonstration
#

export class EasingDemonstration implements Drawing

  Ease = require \../ease

  palette = <[ white red orange yellow green cyan blue red orange yellow green cyan blue ]>

  (@ctx, @size) ->

  draw: (pos, n = 0) ->
    for name, ease-fn of Ease
      @ctx.fill-style = palette[n++]
      for i from 0 to @size.0 by 5
        @box-at [i, pos.1 - @size.1 * ease-fn i/@size.0], [2 2]

