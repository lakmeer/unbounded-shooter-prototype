
# Require

{ id, log, tau, lerp } = require \std

{ Tween } = require \./tween


#
# Flipflopper
#

export class FlipFlopper

  MODE_COCK   = Symbol \cock
  MODE_UNCOCK = Symbol \uncock

  stage-step = tau/3
  stage-to-rotation = (* stage-step)

  normalise-stage = (s) ->
    if s < 0 then 3 - (-s % 3) else s % 3

  normalise-rotation = (θ) ->
    if θ < 0 then tau - (-θ % tau) else θ % tau

  ({ @speed=1 }={}) ->
    @θ     = 0
    @stage = 0
    @mode  = MODE_COCK

  static-to-stage: (d, p) ->
    target-rotation = stage-to-rotation @stage + d
    current-rotation = stage-to-rotation @stage

    switch @mode
    | MODE_COCK =>
      if p is 1
        @mode = MODE_UNCOCK
      else
        @θ = lerp p/2, current-rotation, target-rotation

    | MODE_UNCOCK =>
      if p is 0
        @stage = normalise-stage @stage + d
        @mode = MODE_COCK
        @θ = target-rotation
      else
        @θ = lerp 0.5 + (1 - p)/2, current-rotation, target-rotation

  update: (Δt) ->

