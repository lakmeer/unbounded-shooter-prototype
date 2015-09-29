
# Require

{ id, log, tau } = require \std

{ Drawing } = require \./mixins


#
# Controller State
#

export class ControllerState implements Drawing

  trigger-size = [25 65]

  state-color  = -> if it then \red else \lightgrey

  (@ctx, @size, @flipflopper) ->

  draw: ([x, y], { input-state }) ->

    { flip, flop } = @flipflopper.trigger-state

    input-vel = [ input-state.x, input-state.y ]

    @box-at [x - 80, y - 20], trigger-size, \grey
    @box-at [x + 80, y - 20], trigger-size, \grey
    @box-top [x - 80, y - 52], [25 65 * input-state.flip], \white
    @box-top [x + 80, y - 52], [25 65 * input-state.flop], \white

    @box-at [x - 80, y + 35], [25 25], state-color flip.ignore
    @box-at [x + 80, y + 35], [25 25], state-color flop.ignore

    @ctx.begin-path!
    @ctx.arc x, y, 50, tau/2, tau
    @ctx.line-to x, y + 50
    @ctx.close-path!
    @ctx.stroke!

    @ctx.fill-style = \red
    @ctx.begin-path!
    @ctx.arc x + 50 * input-vel.0, y - 50 * input-vel.1, 6, 0, tau
    @ctx.close-path!
    @ctx.fill!

    @box-at [x - 65, y + 70], [55 25], if input-state.fire    then \yellow else \#333
    @box-at [x + 0,  y + 70], [50 25], if input-state.super   then \yellow else \#333
    @box-at [x + 65, y + 70], [55 25], if input-state.special then \yellow else \#333

