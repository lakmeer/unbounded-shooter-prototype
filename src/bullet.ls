
# Require

{ id, log, rgb } = require \std


#
# Bullet
#

export class Bullet
  (pos, color) ->
    @pos   = [ pos.0, pos.1 ]
    @vel   = [ 0 3000 ]
    @size  = [ 80 220 ]
    @life  = 1
    @Δlife = 1
    @color = color
    @alpha = 1 #.6
    @radius = 20
    @power = 5

  draw: (canvas) ->
    top-size = [ @size.0, @size.1 * 1/4 ]
    btm-size = [ @size.0, @size.1 * 3/4 ]
    top-pos  = [ @pos.0, @pos.1 + @size.1 * 3/8 - @size.1 * 1/4 ]
    btm-pos  = [ @pos.0, @pos.1 - @size.1 * 1/8 - @size.1 * 1/4 ]
    canvas.uptri top-pos, top-size, color: (rgb @color), alpha: @alpha * @life, mode: MODE_ADD
    canvas.dntri btm-pos, btm-size, color: (rgb @color), alpha: @alpha * @life, mode: MODE_ADD

  update: (Δt) ->
    @pos.1 += @vel.1 * Δt
    @life -= @Δlife * Δt
    @life > 0


export class BlendBullet extends Bullet

  separation = 20

  ->
    super ...
    @vel.1 = 2000
    @radius = 40
    @power = 20
    @life = 2
    @size = [120 350]


export class SuperBullet extends Bullet
  ->
    super ...
    @vel.1 = 1000
    @radius = 60
    @power = 50
    @size = [160 500]
    @life = 3


