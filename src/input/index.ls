
# Require

{ id, log } = require \std

Timer = require \../timer

{ GamepadController }   = require \./gamepad
{ KeyboardController }  = require \./keyboard
{ AutomatedController } = require \./automated


#
# Input Manager
#

export class Input

  ->
    @pending-events = [ ]

    @keyboard = new KeyboardController  @push-event
    @gamepad  = new GamepadController   @push-event
    @auto     = new AutomatedController @push-event

  update: (Δt, t) ->
    @auto.update     Δt, t
    @keyboard.update Δt, t
    @gamepad.update  Δt, t

  push-event: (type, value) ~>
    @pending-events.push [ type, value ]

