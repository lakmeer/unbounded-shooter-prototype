
# Require

{ id, log, min, max, sin, cos, tau } = require \std


#
# Gamepad Controller
#

export class AutomatedController

  limit = -> max -2, min 2, it

  (@callback = id) ->
    @state =
      buttons: [ 0 ] * 16
      axes:    [ 0 ] * 4

  proxy-event: (binding, value) ->
    @callback binding, value

  update: (Δt, t) ->
    t = 2*t
    @proxy-event INPUT_X, limit (sin t) #+ (sin -2*t)
    @proxy-event INPUT_Y, limit (cos t) #+ (cos 2*t)
    @proxy-event INPUT_RAW_X, limit (sin t) * 2 #+ (sin -2*t)
    @proxy-event INPUT_RAW_Y, limit (cos t) * 2#+ (cos 2*t)

