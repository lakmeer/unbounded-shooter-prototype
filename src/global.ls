
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
global.INPUT_FIRE       = Symbol \input-fire
global.INPUT_RED        = Symbol \input-red
global.INPUT_GREEN      = Symbol \input-green
global.INPUT_BLUE       = Symbol \input-blue
global.INPUT_BOMB       = Symbol \input-bomb
global.INPUT_FLIP       = Symbol \input-flip
global.INPUT_FLOP       = Symbol \input-fire
global.INPUT_SUPER      = Symbol \input-super
global.INPUT_SPECIAL    = Symbol \input-special
global.INPUT_PAUSE      = Symbol \input-pause
global.INPUT_ROLL_LEFT  = Symbol \input-roll-left
global.INPUT_ROLL_RIGHT = Symbol \input-roll-right
global.INPUT_X          = Symbol \input-move-x
global.INPUT_Y          = Symbol \input-move-y
global.INPUT_RAW_X      = Symbol \input-raw-x
global.INPUT_RAW_Y      = Symbol \input-raw-y

# Asset load status

global.ASSET_LOAD_COMPLETE = Symbol \load-complete
global.ASSET_LOAD_FAILED   = Symbol \load-failed


#
# Experimental feature switches
#

# Flipflop or dodge?
global.EXP_TRIGGER_ACTION_FLIPFLOP = on
global.EXP_TRIGGER_ACTION_DODGE    = not EXP_TRIGGER_ACTION_FLIPFLOP

# Ikaruga or Radiant Silvergun?
global.EXP_FIRE_MODE_IKARUGA = off
global.EXP_FIRE_MODE_RADIANT = not EXP_FIRE_MODE_IKARUGA

# Strict time binding?
global.EXP_STRICT_TIME_BINDING = on

# Direction superlaser or one laser one magent?
global.EXP_MAGNET_AND_LASER = on
global.EXP_DIRECTIONAL_LASERS = not EXP_MAGNET_AND_LASER

# Moving backwards rewinds time?
global.EXP_BACKWARDS_TIME_REWIND = on
global.EXP_BACKWARDS_TIME_SKIPPING = not EXP_BACKWARDS_TIME_REWIND

# Allow sideays movement
global.EXP_USE_LOOSE_CAMERA_TRACKING = off

# Draw a placeholder background
global.EXP_DRAW_BACKGROUND = off


#
# Global options
#

global.GAMEPAD_AXIS_DEADZONE = 0.2
global.DEBUG_SHOW_EASING_TESTS = no
global.LERP_CAMERA_X = on
global.DEBUG_DISABLE_AUDIO = no
global.DEBUG_SIMULATE_LATENCY = no

