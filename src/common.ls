
# Require

{ id, log, lerp, floor, tau } = require \std


#
# Common but domain-specific pure helper functions
#

export lerp-color = (t, start, end) ->
  [ (lerp t, start.0, end.0),
    (lerp t, start.1, end.1),
    (lerp t, start.2, end.2) ]

export rotation-to-color = (θ) ->
  if 0 < θ < tau
    floor (θ/tau) * colors.length
  else
    0

export rotation-to-sprite-index = (θ, frames) ->
  floor frames * (θ % (tau/3)) / (tau/3)

export diamond = ([x, y]) ->
  if x == 0
    [x, y]
  else
    [x/2, y/2]

