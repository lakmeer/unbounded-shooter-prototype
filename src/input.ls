
# Require

{ id, log } = require \std

Timer = require \./timer


#
# Input Manager
#

export class Input

  # Keycodes
  ENTER  = 13
  SPACE  = 32
  ESCAPE = 27
  KEY_A  = 65
  KEY_C  = 67
  KEY_D  = 68
  KEY_E  = 69
  KEY_Q  = 81
  KEY_S  = 83
  KEY_W  = 87
  KEY_X  = 88
  KEY_Z  = 90
  LEFT   = 37
  RIGHT  = 39
  UP     = 38
  DOWN   = 40

  # Gamepad buttons
  BUTTON_A      = 0
  BUTTON_B      = 1
  BUTTON_X      = 2
  BUTTON_Y      = 3
  LEFT_BUMPER   = 4
  RIGHT_BUMPER  = 5
  LEFT_TRIGGER  = 6
  RIGHT_TRIGGER = 7
  SELECT        = 8
  START         = 9
  LEFT_STICK    = 10
  RIGHT_STICK   = 11
  DPAD_TOP      = 12
  DPAD_BOTTOM   = 13
  DPAD_LEFT     = 14
  DPAD_RIGHT    = 15

  # Gamepad axes
  LEFT_STICK_X  = 0
  LEFT_STICK_Y  = 1
  RIGHT_STICK_X = 2
  RIGHT_STICK_Y = 3

  TRIGGER_DIR_PRESS   = Symbol \press
  TRIGGER_DIR_RELEASE = Symbol \release

  global.BUTTON_PAUSE = Symbol \button-pause
  global.BUTTON_FIRE  = Symbol \button-fire
  global.BUTTON_UP    = Symbol \button-up
  global.BUTTON_LEFT  = Symbol \button-left
  global.BUTTON_DOWN  = Symbol \button-down
  global.BUTTON_RIGHT = Symbol \button-right
  global.TRIGGER_FLIP = Symbol \trigger-flip
  global.TRIGGER_FLOP = Symbol \trigger-flop
  global.MOUSE_MOVE   = Symbol \mouse-move
  global.MOVE_X       = Symbol \move-x
  global.MOVE_Y       = Symbol \move-y

  simulated-travel-time = 0.05 * 2

  to-trigger-type = (trigger-ix) ->
    if trigger-ix is LEFT_TRIGGER then TRIGGER_FLIP else TRIGGER_FLOP

  ->
    @pending-events = [ ]

    @sim-triggers =
      * type: TRIGGER_FLIP
        dir:  TRIGGER_DIRECTION_STABLE
        value: 0
        timer: Timer.create simulated-travel-time, disabled: yes
      * type: TRIGGER_FLOP
        value: 0
        dir:  TRIGGER_DIRECTION_STABLE
        timer: Timer.create simulated-travel-time, disabled: yes

    # Gamepad state diff
    @gamepad-prev-state =
      buttons: [ 0 ] * 16
      axes:    [ 0 ] * 4

    document.add-event-listener \mousemove, @handle-mouse
    document.add-event-listener \keydown,   @handle-key on
    document.add-event-listener \keyup,     @handle-key off

  update: (Δt) ->
    if OPT_SIMULATE_GAMEPAD_TRIGGERS
      for trigger in @sim-triggers
        Timer.update-and-stop trigger.timer, Δt
        p = trigger.timer.current / simulated-travel-time

        if trigger.value isnt p
          if trigger.dir is TRIGGER_DIR_RELEASE
            @push-event trigger.type, trigger.timer.target/simulated-travel-time - p
          else
            @push-event trigger.type, p

        if trigger.elapsed and trigger.dir is TRIGGER_DIR_RELEASE
          trigger.dir = TRIGGER_DIRECTION_STABLE

        trigger.value = p

    else
      gamepad = @get-gamepad-state!

      for button, which in gamepad.buttons
        if button.value isnt @gamepad-prev-state.buttons[which]
          @handle-gamepad which, button.value
          @gamepad-prev-state.buttons[which] = button.value

      for raw, which in gamepad.axes
        dead  = -GAMEPAD_AXIS_DEADZONE < raw < GAMEPAD_AXIS_DEADZONE
        value = if dead then 0 else raw

        if value isnt @gamepad-prev-state.axes[which]
          @handle-gamepad-axes which, value
          @gamepad-prev-state.axes[which] = value


  push-event: (type, arg) ->
    @pending-events.push [ type, arg ]

  simulate: (trigger, target, dir) ->
    direction = if dir then TRIGGER_DIR_PRESS else TRIGGER_DIR_RELEASE
    trigger.timer.target = target

    if (direction isnt trigger.dir)
      if trigger.timer.active
        trigger.timer.current = trigger.timer.target - trigger.timer.current
      else
        Timer.reset trigger.timer
      trigger.dir = direction

  simulate-trigger-half: (side, dir) ->
    @simulate @sim-triggers[side], simulated-travel-time/2, dir

  simulate-trigger-motion: (side, dir) ->
    @simulate @sim-triggers[side], simulated-travel-time, dir


  # Keyboard

  handle-key: (dir) -> ({ which }:event) ~>
    if event.shift-key then log which
    if not @dispatch-key-response dir, which
      return event
    event.prevent-default!
    return false

  handle-mouse: ({ pageX, pageY }) ~>
    @push-event MOUSE_MOVE, [ pageX/window.inner-width, pageY/window.inner-height ]

  dispatch-key-response: (dir, which) ->
    switch which
    | KEY_Z  => @simulate-trigger-motion  0, dir
    | KEY_C  => @simulate-trigger-motion  1, dir
    | KEY_A  => @simulate-trigger-half    0, dir
    | KEY_D  => @simulate-trigger-half    1, dir
    | KEY_S  => @push-event BUTTON_FIRE,  dir
    | KEY_X  => @push-event BUTTON_FIRE,  dir
    | UP     => @push-event MOVE_Y,  +1 * dir
    | DOWN   => @push-event MOVE_Y,  -1 * dir
    | LEFT   => @push-event MOVE_X,  -1 * dir
    | RIGHT  => @push-event MOVE_X,  +1 * dir
    | ESCAPE => (if dir then frame-driver.toggle!)
    | _ => return false


  # Gamepad

  get-gamepad-state: ->
    navigator.get-gamepads!0

  handle-gamepad: (which, value) ->
    switch which
    | LEFT_TRIGGER, RIGHT_TRIGGER => @handle-trigger (to-trigger-type which), value
    | otherwise => @handle-button which, value

  handle-trigger: (type, p) ->
    @push-event type, p

  handle-button: (which, dir) ->
    switch which
    | BUTTON_A => @push-event BUTTON_FIRE, dir

  handle-gamepad-axes: (which, value) ->
    if  which is LEFT_STICK_X
      log which, value

    switch which
    | LEFT_STICK_X => @push-event MOVE_X, value
    | LEFT_STICK_Y => @push-event MOVE_Y, -value
    | otherwise => void

