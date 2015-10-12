
# Require

{ id, log, tau, abs, lerp } = require \std

{ Tween } = require \./tween

{ mix-ease, Linear } = Ease = require \./ease


#
# Flipflopper
#

export class LatchingFlipFlopper

  MODE_IDLE      = Symbol \idle
  MODE_COCKING   = Symbol \cocking
  MODE_COCKED    = Symbol \cocked
  MODE_UNCOCKING = Symbol \uncocking
  MODE_REVERSING = Symbol \reversing

  d-sym = (n) -> <[ FLIP IDLE FLOP ]>[n + 1]
  stage-step = tau/3
  stage-to-rotation = (* stage-step)

  normalise-stage = (s) ->
    if s < 0 then 3 - (-s % 3) else s % 3

  normalise-rotation = (θ) ->
    if θ < 0 then tau - (-θ % tau) else θ % tau


  ({ @speed=1 }={}) ->
    @θ     = 0
    @stage = 0
    @mode  = MODE_IDLE
    @cock-direction = 0
    @reverse-trigger = 0
    @ignored-trigger = 0

    @trigger-state =
      flip:
        ingore: no
      flop:
        ingore: no

  rotation:~ ->
    normalise-rotation @θ

  static-to-stage: (d, p) ->
    if @reverse-trigger is d
      if p is 0
        @reverse-trigger = 0
        @cock-direction = 0
        log \revert-release: d-sym d
      else log \revert: d-sym d
      return

    if @ignored-trigger is d
      if p is 0
        @ignored-trigger = 0
        @cock-direction = 0
        log \ignore-release: d-sym d
      else log \ignore: d-sym d
      return

    switch @mode
    | MODE_IDLE =>
      @mode = MODE_COCKING
      @cock-direction = d
      @cock ...

    | MODE_COCKING =>
      if @cock-direction is d
        @cock ...
      else
        @cock-direction = d
        @ignored-trigger = d * -1
        @cock ...

    | MODE_COCKED =>
      if @cock-direction is d
        @mode = MODE_UNCOCKING
        @uncock ...
      else
        @mode = MODE_REVERSING
        @ignored-trigger = d * -1
        @reverse ...

    | MODE_UNCOCKING =>
      if @cock-direction is d
        @uncock ...
      else
        @mode = MODE_REVERSING
        @ignored-trigger = d * -1
        @reverse ...

    | MODE_REVERSING =>
      @reverse ...

  idle: (d) ->
    @stage = normalise-stage @stage + d
    @θ     = stage-to-rotation @stage
    @mode  = MODE_IDLE
    @cock-direction = 0
    @ignored-trigger = 0

  cock: (d, p) ->
    target-rotation  = stage-to-rotation @stage + d
    current-rotation = stage-to-rotation @stage

    @θ = lerp (Ease.PowerOut3 p)/2, current-rotation, target-rotation
    if p is 1 then @mode = MODE_COCKED
    if p is 0 then @idle 0

  uncock: (d, p) ->
    target-rotation  = stage-to-rotation @stage + d
    current-rotation = stage-to-rotation @stage

    if p is 0
      @idle d
    else
      @θ = lerp 0.5 + (1 - (Ease.Power3 p))/2, current-rotation, target-rotation

  reverse: (d, p) ->
    target-rotation  = stage-to-rotation @stage
    current-rotation = stage-to-rotation @stage - d/2
    @θ = lerp p, current-rotation, target-rotation

    if p is 1
      @idle 0
      @reverse-trigger = d
      @cock-direction = 0



export class EasyFlipFlopper

  threshold          = tau/60
  return-threshold   = 0.1
  stage-step         = tau/3
  stage-to-rotation  = (* stage-step)
  trigger-name       = (d) -> if d is -1 then TRIGGER_FLIP else TRIGGER_FLOP
  normalise-stage    = (s) -> if s < 0 then 3 - (-s % 3) else s % 3
  normalise-rotation = (θ) -> if θ < 0 then tau - (-θ % tau) else θ % tau

  MODE_IDLE = Symbol \idle
  MODE_FLIP = Symbol \flip
  MODE_FLOP = Symbol \flop

  TRIGGER_FLIP = \flip
  TRIGGER_FLOP = \flop

  custom-ease = Ease.Power2 #mix-ease Power2, PowerOut4

  ({ @speed=1 }={}) ->
    @θ     = 0
    @stage = 0
    @mode  = MODE_IDLE
    @direction = 0

    @trigger-state =
      "#TRIGGER_FLIP": ignore: no
      "#TRIGGER_FLOP": ignore: no

  rotation:~ ->
    normalise-rotation @θ

  static-to-stage: (d, p) ->
    trigger = trigger-name d

    if @trigger-state[trigger].ignore
      if p < return-threshold
        @trigger-state[trigger].ignore = no

    else
      target  = stage-to-rotation @stage + d
      current = stage-to-rotation @stage

      @θ = lerp (custom-ease p), current, target

      if (abs @θ - target) < threshold
        @θ = target
        @stage += d
        @trigger-state[trigger].ignore = yes

  rotation:~ ->
    normalise-rotation @θ



export FlipFlopper = EasyFlipFlopper

