
# Require

{ id, log } = require \std


#
# Camera Offset Effects
#

export class CameraJoltEffect

  ({ @offset, @time }) ->
    @elapsed-time = 0
    @progress = 0

  update: (Δt) ->
    @elapsed-time += Δt
    @progress = @elapsed-time / @time
    return @progress <= 1

  get-x-offset: ->
    @offset.0 * (1 - @progress)

  get-y-offset: ->
    @offset.1 * (1 - @progress)


export class CameraShakeEffect

  { RandomStream } = require \./random-stream

  ({ @offset, @time }) ->
    @elapsed-time = 0
    @progress = 0
    @random-x = new RandomStream min: -@offset.0, max: @offset.0, speed: @time / 1000
    @random-y = new RandomStream min: -@offset.1, max: @offset.1, speed: @time / 1000

  update: (Δt) ->
    @elapsed-time += Δt
    @progress = @elapsed-time / @time
    @random-x.update Δt
    @random-y.update Δt
    return @progress <= 1

  get-x-offset: ->
    @random-x.get-value! * (1 - @progress)

  get-y-offset: ->
    @random-y.get-value! * (1 - @progress)

