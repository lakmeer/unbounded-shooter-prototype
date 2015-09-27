
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
  KEY_Z  = 90
  KEY_X  = 88
  KEY_C  = 67
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

  simulated-travel-time = 0.05 * 10

  ->
    @pending-events = [ ]

    @sim-triggers =
      * type: TRIGGER_FLIP
        value: 0
        timer: Timer.create simulated-travel-time, disabled: yes
        dir:  TRIGGER_DIRECTION_STABLE
      * type: TRIGGER_FLOP
        value: 0
        timer: Timer.create simulated-travel-time, disabled: yes
        dir:  TRIGGER_DIRECTION_STABLE

    document.add-event-listener \mousemove, @handle-mouse
    document.add-event-listener \keydown,   @handle-key on
    document.add-event-listener \keyup,     @handle-key off

  update: (Δt) ->
    for trigger in @sim-triggers
      Timer.update-and-stop trigger.timer, Δt
      p = Timer.get-progress trigger.timer

      if trigger.value isnt p
        if trigger.dir is TRIGGER_DIR_RELEASE
          @push-event trigger.type, 1 - p
        else
          @push-event trigger.type, p

      if trigger.elapsed and trigger.dir is TRIGGER_DIR_RELEASE
        trigger.target = simulated-travel-time
        trigger.dir = TRIGGER_DIRECTION_STABLE

      trigger.value = p

  push-event: (type, arg) ->
    @pending-events.push [ type, arg ]

  simulate-trigger-motion: (side, dir) ->
    trigger   = @sim-triggers[side]
    direction = if dir then TRIGGER_DIR_PRESS else TRIGGER_DIR_RELEASE

    if (direction isnt trigger.dir)
      if trigger.timer.active
        trigger.timer.current = trigger.timer.target - trigger.timer.current
      else
        Timer.reset trigger.timer

      trigger.dir = direction

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
    | KEY_X  => @push-event BUTTON_FIRE,  dir
    | UP     => @push-event BUTTON_UP,    dir
    | LEFT   => @push-event BUTTON_LEFT,  dir
    | DOWN   => @push-event BUTTON_DOWN,  dir
    | RIGHT  => @push-event BUTTON_RIGHT, dir
    | ESCAPE => (if dir then frame-driver.toggle!)
    | _ => return false

