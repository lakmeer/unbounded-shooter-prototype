
{ id, log } = require \std


#
# Sprite
#

export class Sprite

  (src, [ width, height ], frames) ->

    image = new Image
    image.width  = width * frames
    image.height = height
    image.src    = src

    @index  = 0
    @width  = width
    @height = height
    @image  = image
    @frames = frames

  blit-to: (ctx) ->



