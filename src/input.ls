
# Require

{ id, log } = require \std


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

  ->

    @state =
      up:    off
      down:  off
      left:  off
      right: off

      fire:  off

      flip-on: off
      flop-on: off
      flip-off: off
      flop-off: off

      mouse-x: 0
      mouse-y: 0

    document.add-event-listener \mousemove, ({ pageX, pageY }) ~>
      input.state.mouse-x = pageX / window.inner-width
      input.state.mouse-y = pageY / window.inner-height

    document.add-event-listener \keydown, ({ which }:event) ~>
      if event.shift-key then log which
      let this = @state
        switch which
        | ESCAPE => frame-driver.toggle!
        | ENTER  => void
        | SPACE  => void
        | KEY_Z  => @flip-on = on
        | KEY_C  => @flop-on = on
        | KEY_X  => @fire  = on
        | UP     => @up    = on
        | LEFT   => @left  = on
        | DOWN   => @down  = on
        | RIGHT  => @right = on
        | _  => return event
        event.prevent-default!
        return false

    document.add-event-listener \keyup, ({ which }:event) ~>
      if event.shift-key then log which
      let this = @state
        switch which
        | SPACE  => void
        | KEY_Z  => @flip-on = off; @flip-off = on
        | KEY_C  => @flop-on = off; @flop-off = on
        | KEY_X  => @fire  = off
        | UP     => @up    = off
        | LEFT   => @left  = off
        | DOWN   => @down  = off
        | RIGHT  => @right = off
        | _  => return event
        event.prevent-default!
        return false

