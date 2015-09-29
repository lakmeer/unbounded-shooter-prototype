
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

    event-bindings = new Map
      ..set INPUT_FIRE,    @push-event INPUT_FIRE
      ..set INPUT_FLIP,    @push-event INPUT_FLIP
      ..set INPUT_FLOP,    @push-event INPUT_FLOP
      ..set INPUT_SUPER,   @push-event INPUT_SUPER
      ..set INPUT_PAUSE,   @push-event INPUT_PAUSE
      ..set INPUT_X,       @push-event INPUT_X
      ..set INPUT_Y,       @push-event INPUT_Y
      ..set INPUT_SPECIAL, @push-event INPUT_SPECIAL

    @keyboard = new KeyboardController event-bindings
    @gamepad  = new GamepadController event-bindings

  update: (Δt) ->
    @keyboard.update Δt
    @gamepad.update Δt

  push-event: (type) -> (value) ~>
    log \input-event type, value
    @pending-events.push [ type, value ]

