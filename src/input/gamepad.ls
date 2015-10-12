
# Require

{ id, log } = require \std

const NO_BINDING = Symbol \no-binding


# Input codes (xbox)

const BUTTON_A          = 0
const BUTTON_B          = 1
const BUTTON_X          = 2
const BUTTON_Y          = 3
const LEFT_TRIGGER      = 6
const RIGHT_TRIGGER     = 7
const LEFT_BUMPER       = 4
const RIGHT_BUMPER      = 5
const BUTTON_SELECT     = 8
const BUTTON_START      = 9
const LEFT_STICK_CLICK  = 10
const RIGHT_STICK_CLICK = 11
const DPAD_TOP          = 12
const DPAD_BOTTOM       = 13
const DPAD_LEFT         = 14
const DPAD_RIGHT        = 15

const LEFT_STICK_X      = 0
const LEFT_STICK_Y      = 1
const RIGHT_STICK_X     = 2
const RIGHT_STICK_Y     = 3


# Key layout (xbox)

flipflop-binding = new Map
  ..set BUTTON_A,      INPUT_FIRE
  ..set BUTTON_Y,      INPUT_SUPER
  ..set BUTTON_B,      INPUT_SPECIAL
  ..set LEFT_TRIGGER,  INPUT_FLIP
  ..set RIGHT_TRIGGER, INPUT_FLOP
  ..set BUTTON_START,  INPUT_PAUSE

radiant-binding = new Map
  ..set BUTTON_A,      INPUT_GREEN
  ..set BUTTON_X,      INPUT_BLUE
  ..set BUTTON_B,      INPUT_RED
  ..set LEFT_TRIGGER,  INPUT_ROLL_LEFT
  ..set RIGHT_TRIGGER, INPUT_ROLL_RIGHT
  ..set BUTTON_START,  INPUT_PAUSE

axis-bindings = new Map
  ..set LEFT_STICK_X,  INPUT_RAW_X
  ..set LEFT_STICK_Y,  INPUT_RAW_Y

key-bindings =
  if EXP_FIRE_MODE_RADIANT
    radiant-binding
  else
    flipflop-binding


#
# Gamepad Controller
#

export class GamepadController

  (@callback = id) ->
    @state =
      buttons: [ 0 ] * 16
      axes:    [ 0 ] * 4

  proxy-event: (value, binding) ->
    @callback binding, value

  update: (Δt) ->
    gamepad = navigator.get-gamepads!0

    if gamepad
      for button, which in gamepad.buttons
        if button.value isnt @state.buttons[which]
          log 'Gamepad:', which, key-bindings.get which
          @proxy-event button.value, key-bindings.get which
          @state.buttons[which] = button.value

      for raw, which in gamepad.axes
        dead  = -GAMEPAD_AXIS_DEADZONE < raw < GAMEPAD_AXIS_DEADZONE
        value = if dead then 0 else raw
        value = if which is LEFT_STICK_Y then -value else value

        if value isnt @state.axes[which]
          @proxy-event value, axis-bindings.get which
          @state.axes[which] = value

