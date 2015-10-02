
# Require

{ id, log, min, max, sin, cos, tau } = require \std


#
# Gamepad Controller
#

export class AutomatedController

  radius = 1.5
  limit = -> max -1.5, min 1.5, it

  (@callback = id) ->
    @state =
      buttons: [ 0 ] * 16
      axes:    [ 0 ] * 4

  proxy-event: (binding, value) ->
    @callback binding, value

  update: (Δt, t) ->
    t = 2*t
    @proxy-event INPUT_X, limit sin t
    @proxy-event INPUT_Y, limit cos t
    @proxy-event INPUT_RAW_X, limit (sin t) * radius
    @proxy-event INPUT_RAW_Y, limit (cos t) * radius

