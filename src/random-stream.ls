
{ id, log, lerp, floor, random-range } = require \std

{ LimitedArray } = require \./limited-array


export class RandomStream

  ({ @min, @max, @buffer-size = 10, @speed = 1 }) ->
    @buffer = new LimitedArray @buffer-size
    @time-to-next-value = 0

    for i from 0 til @buffer-size
      @buffer.push random-range @min, @max

  get-value: ->
    lerp @time-to-next-value/@speed, @buffer.items[0], @buffer.items[1]

  update: (Δt) ->
    @time-to-next-value += Δt

    if @time-to-next-value >= @speed
      @time-to-next-value %= @speed
      @buffer.shift!

    if @buffer.space-available
      @buffer.push random-range @min, @max

