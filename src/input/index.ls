
# Require

{ id, log } = require \std

Timer = require \../timer

{ KeyboardController } = require \./keyboard
{ GamepadController }  = require \./gamepad


#
# Input Manager
#

export class Input

  ->
    @pending-events = [ ]

    @keyboard = new KeyboardController @push-event
    @gamepad  = new GamepadController  @push-event

  update: (Δt) ->
    @keyboard.update Δt
    @gamepad.update Δt

  push-event: (type, value) ~>
    @pending-events.push [ type, value ]

