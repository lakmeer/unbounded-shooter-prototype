
export class LimitedArray

  (@limit) ->
    @buffer = []

  push: (n) ->
    @buffer.push n
    if @buffer.length > @limit
      @buffer.shift!

  unshift: (n) ->
    @buffer.unshift n
    if @buffer.length > @limit
      @buffer.pop!

  pop: -> @buffer.pop!

  shift: -> @buffer.shift!

  items:~ -> @buffer

  length:~ -> @buffer.length

  space-available:~ -> @buffer.length < @limit

