
# Require

{ id, log } = require \std

Timer = require \../timer


# Reference Constants

const ENTER  = 13
const SPACE  = 32
const ESCAPE = 27
const KEY_A  = 65
const KEY_C  = 67
const KEY_D  = 68
const KEY_E  = 69
const KEY_Q  = 81
const KEY_S  = 83
const KEY_W  = 87
const KEY_X  = 88
const KEY_Z  = 90
const LEFT   = 37
const RIGHT  = 39
const UP     = 38
const DOWN   = 40

const TRIGGER_DIR_STABLE  = Symbol \trigger-direction-stable
const TRIGGER_DIR_PRESS   = Symbol \trigger-direction-press
const TRIGGER_DIR_RELEASE = Symbol \trigger-direction-release


#
# Keyboard Controller
#

export class KeyboardController

  simulated-travel-time = 0.05 * 2

  (@callback = id) ->

    @sim-triggers =
      * type: INPUT_FLIP
        dir:  TRIGGER_DIR_STABLE
        value: 0
        timer: Timer.create simulated-travel-time, disabled: yes

      * type: INPUT_FLOP
        value: 0
        dir:  TRIGGER_DIR_STABLE
        timer: Timer.create simulated-travel-time, disabled: yes

    @cursor-state =
      up:    off
      down:  off
      left:  off
      right: off

    document.add-event-listener \keydown, @handle-key on
    document.add-event-listener \keyup,   @handle-key off

  proxy-event: (type, value) ->
    @callback type, value

  update: (Δt) ->
    for trigger in @sim-triggers
      Timer.update-and-stop trigger.timer, Δt
      p = trigger.timer.current / simulated-travel-time

      if trigger.value isnt p
        if trigger.dir is TRIGGER_DIR_RELEASE
          @proxy-event trigger.type, trigger.timer.target/simulated-travel-time - p
        else
          @proxy-event trigger.type, p

      if trigger.elapsed and trigger.dir is TRIGGER_DIR_RELEASE
        trigger.dir = TRIGGER_DIRECTION_STABLE

      trigger.value = p

  handle-key: (dir) -> ({ which }:event) ~>
    if event.shift-key then log which
    if not @dispatch-key-response dir, which
      return event
    event.prevent-default!
    return false

  dispatch-key-response: (dir, which) ->
    switch which
    | KEY_Z  => @simulate-trigger  0, dir, 1
    | KEY_C  => @simulate-trigger  1, dir, 1
    | KEY_A  => @simulate-trigger  0, dir, 0.5
    | KEY_D  => @simulate-trigger  1, dir, 0.5
    | KEY_S  => @proxy-event INPUT_FIRE,  dir
    | KEY_X  => @proxy-event INPUT_FIRE,  dir
    | UP     => @cursor-velocity-y \up,    dir
    | DOWN   => @cursor-velocity-y \down,  dir
    | LEFT   => @cursor-velocity-x \left,  dir
    | RIGHT  => @cursor-velocity-x \right, dir
    | ESCAPE => @proxy-event INPUT_PAUSE, (if dir then frame-driver.toggle!)

  cursor-velocity-x: (key, dir) ->
    @cursor-state[key] = dir
    value = @cursor-state.right - @cursor-state.left
    @proxy-event INPUT_RAW_X, value
    @proxy-event INPUT_X, value

  cursor-velocity-y: (key, dir) ->
    @cursor-state[key] = dir
    value = @cursor-state.up - @cursor-state.down
    @proxy-event INPUT_RAW_Y, value
    @proxy-event INPUT_Y, value

  simulate: (trigger, target, dir) ->
    direction = if dir then TRIGGER_DIR_PRESS else TRIGGER_DIR_RELEASE
    trigger.timer.target = target

    if (direction isnt trigger.dir)
      if trigger.timer.active
        trigger.timer.current = trigger.timer.target - trigger.timer.current
      else
        Timer.reset trigger.timer
      trigger.dir = direction

  simulate-trigger: (side, dir, mult = 2) ->
    @simulate @sim-triggers[side], simulated-travel-time * mult, dir

