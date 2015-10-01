
export id = -> it

export log = -> console.log.apply console, &; &0

export raf = window.request-animation-frame

export lerp = (a, t, b) -> a + t * (b - a)

export floor = Math.floor

export sqrt = Math.sqrt

export abs = Math.abs

export min = Math.min

export sin = Math.sin

export cos = Math.cos

export max = Math.max

export asin = Math.asin

export v2 =
  hyp   : (v) -> sqrt (v.0 * v.0 + v.1 * v.1)
  norm  : (v) -> d = v2.hyp v; if d is 0 then [0 0] else [ v.0/d, v.1/d ]
  add   : (a, b) -> [ a.0 + b.0, a.1 + b.1 ]
  sub   : (a, b) -> [ a.0 - b.0, a.1 - b.1 ]
  scale : (v, f) -> [ v.0 * f, v.1 * f ]
  dist  : (a, b) -> sqrt v2.dist2 a, b
  dist2 : (a, b) -> x = [b.0 - a.0]; y = [b.1 - a.1]; x*x+y*y

export box = (n) -> [ n, n ]

export rnd = (n) -> n * Math.random!

export div = (a, b) -> floor a / b

export pi = Math.PI

export tau = pi * 2

export flip = (λ) -> (a, b) -> λ b, a

export delay = flip set-timeout

export limit = (min, max, n) --> if n < min then min else if n > max then max else n

export wrap = (min, max, n) --> if n < min then max else if n > max then min else n

export z = -> floor it * 255

export rgb = (r,g,b) -> "rgb(#{z r},#{z g},#{z b})"

export random-from = (xs) -> xs[ floor Math.random! * xs.length ]

export random-range = (a, b) -> a + (rnd b - a)

export ids = -> if it is 0 then 0 else 1 / it*it

export idd = -> if it is 0 then 0 else 1 / it

export base64 = (buffer, output = "") ->
  bytes = new Uint8Array( buffer )
  for i from 0 to bytes.byteLength => output += String.fromCharCode bytes[i]
  window.btoa output

export pad-two = (str) -> if str.length < 2 then "0#str" else str

export hex = (decimal) -> pad-two (floor decimal).to-string 16

export rgb = ([r,g,b]) -> "##{hex r*255}#{hex g*255}#{hex b*255}"

export lerp = (t, a, b) -> a + t * (b - a)

export ease = (t, a, b, λ) -> a + (λ t) * (b - a)


# Physics processors

export physics = (o, Δt) ->
  f = if o.friction then that else 1
  o.vel = ((o.acc `v2.scale` Δt) `v2.add` o.vel) `v2.scale` f
  o.pos = (o.vel `v2.scale` Δt) `v2.add` o.pos `v2.add` (o.acc `v2.scale` (0.5 * Δt * Δt))

export dampen = (o, damp, Δt) ->
  o.vel = (o.vel `v2.scale` damp)
  o.pos = (o.vel `v2.scale` Δt) `v2.add` o.pos


# Special logging

color-log = (col) -> (text, ...rest) ->
  log \%c + text, "color: #col", ...rest

red-log   = color-log '#e42'
green-log = color-log '#1d3'

export sfx = color-log '#28e'

