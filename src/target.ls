
# Require

{ id, log, rgb } = require \std


#
# Target
#
# A dumb target that has a color and collision radius but doesn't shoot back
#

export class Target1
  (pos, color) ->
    @pos    = [ pos.0, pos.1 ]
    @vel    = [0 0]
    @size   = [90 90]
    @health = 100
    @alive  = yes
    @color  = color
    @radius = 30

  damage: (amount) ->
    @health -= amount
    @alive = @health <= 0

  draw: (canvas) ->
    canvas.dntri @pos, @size, color: rgb @color
    canvas.stroke-circle @pos, @radius, color: \white

  update: (Δt) ->


#
# Bigger
#

export class Target2 extends Target1
  (pos, color) ->
    super ...
    @size   = [150 150]
    @health = 250
    @radius = 50


#
# Biggest
#

export class Target3 extends Target1
  (pos, color) ->
    super ...
    @size   = [300 300]
    @health = 500
    @radius = 90

