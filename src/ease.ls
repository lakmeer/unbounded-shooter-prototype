
# Require

{ id, log } = require \std


#
# Easing functions
#

export Linear    = (n) -> n

export Power2    = (n) -> n * n

export Power3    = (n) -> n * n * n

export Power4    = (n) -> n * n * n * n

export PowerOut2 = (n, m = 1 - n) -> 1 - m * m

export PowerOut3 = (n, m = 1 - n) -> 1 - m * m * m

export PowerOut4 = (n, m = 1 - n) -> 1 - m * m * m * m

