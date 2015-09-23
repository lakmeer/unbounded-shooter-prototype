
# Require

{ id, log, asin, v2 } = require \std


#
# Physics Component
#
# Knows about physics properties and how to simulate them
#

export create = ({ p, v, a, f }) ->
  pos: if p then [p.0, p.1] else [0 0]
  vel: if v then [v.0, v.1] else [0 0]
  acc: if a then [a.0, a.1] else [0 0]
  fri: f or 1

export coerce = (e, { p, v, a, f }) ->
  e.pos = if p then [p.0, p.1] else [0 0]
  e.vel = if v then [v.0, v.1] else [0 0]
  e.acc = if a then [a.0, a.1] else [0 0]
  e.fri = f or 1

export update = (e, Δt) ->
  e.vel = (e.vel `v2.add` (e.acc `v2.scale` Δt)) `v2.scale` e.fri
  e.pos =  e.pos `v2.add` (e.vel `v2.scale` Δt)  `v2.add`  (e.acc `v2.scale` (0.5*Δt*Δt))

export set-pos = (e, [ x, y ]) ->
  e.pos.0 = x
  e.pos.1 = y

export set-vel = (e, [ x, y ]) ->
  e.vel.0 = x
  e.vel.1 = y

export set-acc = (e, [ x, y ]) ->
  e.acc.0 = x
  e.acc.1 = y

export add-pos = (e, [ x, y ]) ->
  e.pos.0 += x
  e.pos.1 += y

export add-vel = (e, [ x, y ]) ->
  e.vel.0 += x
  e.vel.1 += y

export get-bearing-to = (e, [ x, y ]) ->
  xx = x - e.pos.0
  yy = y - e.pos.1
  asin -xx/v2.hyp [ xx, yy ]

export clone-pos = (e) ->
  [ e.pos.0, e.pos.1 ]

export move = set-pos

