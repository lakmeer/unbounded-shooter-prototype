
# Require

{ id, log } = require \std

Timer = require \./timer


#
# Input Manager
#

export class Input

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

  simulated-travel-time = 0.05 * 2

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

    document.add-event-listener \mousemove, @handle-mouse
    document.add-event-listener \keydown,   @handle-key on
    document.add-event-listener \keyup,     @handle-key off

  update: (Δt) ->
    for trigger in @sim-triggers
      Timer.update-and-stop trigger.timer, Δt
      #p = Timer.get-progress trigger.timer
      p = trigger.timer.current / simulated-travel-time

      if trigger.value isnt p
        if trigger.dir is TRIGGER_DIR_RELEASE
          @push-event trigger.type, trigger.timer.target/simulated-travel-time - p
        else
          @push-event trigger.type, p

      if trigger.elapsed and trigger.dir is TRIGGER_DIR_RELEASE
        trigger.dir = TRIGGER_DIRECTION_STABLE

      trigger.value = p

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
    | UP     => @push-event BUTTON_UP,    dir
    | LEFT   => @push-event BUTTON_LEFT,  dir
    | DOWN   => @push-event BUTTON_DOWN,  dir
    | RIGHT  => @push-event BUTTON_RIGHT, dir
    | ESCAPE => (if dir then frame-driver.toggle!)
    | _ => return false

