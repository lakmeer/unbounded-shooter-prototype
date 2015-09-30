
#
# Global Constants
#

# Rendering modes
global.MODE_COLOR  = Symbol \color
global.MODE_NORMAL = Symbol \normal
global.MODE_ADD    = Symbol \add

# Color wheel segments
global.colors =
  [1 0 0] [1 1 0] [0 1 0]
  [0 1 0] [0 1 1] [0 0 1]
  [0 0 1] [1 0 1] [1 0 0]

# Game states
global.FIRE_MODE_ALTERNATE = Symbol \alternate
global.FIRE_MODE_BLEND     = Symbol \blend

# Controller input signals
global.INPUT_FIRE    = Symbol \input-fire
global.INPUT_FLIP    = Symbol \input-flip
global.INPUT_FLOP    = Symbol \input-fire
global.INPUT_SUPER   = Symbol \input-super
global.INPUT_PAUSE   = Symbol \input-pause
global.INPUT_X       = Symbol \input-move-x
global.INPUT_Y       = Symbol \input-move-y
global.INPUT_SPECIAL = Symbol \input-special
global.INPUT_RAW_X   = Symbol \input-raw-x
global.INPUT_RAW_Y   = Symbol \input-raw-y


#
# Global options
#

global.GAMEPAD_AXIS_DEADZONE = 0.2
global.DEBUG_SHOW_EASING_TESTS = no

