
#
# Bullet
#

export create = (pos, vel, color) ->
  pos:  [ pos.0, pos.1 ]
  vel:  [ 0 vel ]
  size: [ 100 300 ]
  life: 1
  Δlife: 1
  color: color
  alpha: 1 #.6

export draw = (canvas, { pos, size, alpha, color, life }) ->
  top-size = [ size.0, size.1 * 1/4 ]
  btm-size = [ size.0, size.1 * 3/4 ]
  top-pos  = [ pos.0, pos.1 + size.1 * 3/8 ]
  btm-pos  = [ pos.0, pos.1 - size.1 * 1/8 ]
  canvas.uptri top-pos, top-size, color: color, alpha: alpha * life, mode: MODE_ADD
  canvas.dntri btm-pos, btm-size, color: color, alpha: alpha * life, mode: MODE_ADD

