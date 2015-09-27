
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

  normalise-stage   = (s) ->
    if s < 0 then 3 - (-s % 3) else s % 3

  normalise-rotation = (θ) ->
    if θ < 0 then tau - (-θ % tau) else θ % tau

  ({ @speed=1 }={}) ->
    @θ     = 0
    @Δθ    = 0
    @stage = 0
    @mode  = MODE_COCK
    #@tween = Tween.Null

  get-rotation: ->
    @θ + @Δθ

  #tween-to-stage: (d) ->
    #@stage += d
    #@tween = new Tween do
      #from: @θ,
        #to: (stage-to-rotation @stage),
        #in: @speed,
        #with: Ease.PowerOut4

  static-to-stage: (d, p) ->
    target-rotation = stage-to-rotation @stage + d

    if @mode is MODE_COCK
      if p is 1
        @stage = normalise-stage @stage + d
        @θ = normalise-rotation target-rotation
        @Δθ = 0
        log \STAGE @stage
        @mode = MODE_UNCOCK
      else
        @Δθ = lerp p, @θ, target-rotation
    else
      if p is 0
        @stage = normalise-stage @stage + d
        @θ = normalise-rotation target-rotation
        @Δθ = 0
        log \STAGE @stage
        @mode = MODE_COCK
      else
        @Δθ = lerp (1 - p), @θ, target-rotation


  update: (Δt) ->
    #if @tween.active
    #@θ = @tween.value

    #if @tween.elapsed
    #@stage = normalise-stage @stage
    #@θ = normalise-rotation @θ

