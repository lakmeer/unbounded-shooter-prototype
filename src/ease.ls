
# Require

{ id, log } = require \std


#
# Easing functions
#

# Helpers

export mix-ease = (In, Out) -> (n) ->
  if n < 1/2
    1/2 * In n * 2
  else
    1/2 + 1/2 * Out (n - 1/2) * 2


# In-functions

export Linear    = (n) -> n

export Power2    = (n) -> n * n

export Power3    = (n) -> n * n * n

export Power4    = (n) -> n * n * n * n


# Out-functions

export PowerOut2 = (n, m = 1 - n) -> 1 - m * m

export PowerOut3 = (n, m = 1 - n) -> 1 - m * m * m

export PowerOut4 = (n, m = 1 - n) -> 1 - m * m * m * m


# Mixed functions

export Swing2 = mix-ease Power2, PowerOut2

export Swing3 = mix-ease Power3, PowerOut3

export Swing4 = mix-ease Power4, PowerOut4

