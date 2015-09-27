
# Require

{ id, log } = require \std


#
# Tween
#

export class Tween

  all-tweens = []

  ({ @from = 0, @to = 1, @in = 1, @with = Ease.Linear }) ->
    # log 'new Tween:', @from, @to
    @time = 0
    @range = @to - @from
    @elapsed = no
    @active = yes
    all-tweens.push this

  update: (Δt) ->
    @time += Δt
    if @time >= @in
      @time = @in
      @elapsed = yes
      @active = no
    @value = @from + @range * @with @time/@in
    return not @elapsed

  @update-all = (Δt) ->
    all-tweens := all-tweens.filter (.update Δt)

  @Null =
    elapsed: no
    active: no
    value: 0

