
#
# Bullet
#

export create = (pos) ->
  pos:  [ pos.0, pos.1 ]
  vel:  [ 0 5000 ]
  size: [ 100 300 ]
  life: 1
  Δlife: 1
  alpha: 1 #.6

export draw = (canvas, { pos, size, alpha, life }) ->
  top-size = [ size.0, size.1 * 1/4 ]
  btm-size = [ size.0, size.1 * 3/4 ]
  top-pos  = [ pos.0, pos.1 + size.1/4 ]
  btm-pos  = [ pos.0, pos.1 - size.1/4 ]
  canvas.uptri top-pos, top-size, color: \red, alpha: alpha * life, mode: MODE_COLOR
  canvas.dntri btm-pos, btm-size, color: \red, alpha: alpha * life, mode: MODE_COLOR

