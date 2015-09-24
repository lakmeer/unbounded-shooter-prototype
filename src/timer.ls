
{ id, log } = require \std

#
# Normal Timer
#
# Becomes inactive once completed but resets whenever you want
#

export create = (target, { disabled=no }={}) ->
  target: target
  current: 0
  elapsed: no
  active: not disabled

export update-and-stop = (timer, Δt) ->
  if timer.active
    if timer.current + Δt >= timer.target
      timer.current = timer.target
      timer.elapsed = yes
      timer.active = no
    else
      timer.current += Δt
      timer.elapsed = no

export update-and-carry = (timer, Δt) ->
  if timer.active
    if timer.current + Δt >= timer.target
      timer.elapsed = yes
      timer.current = (timer.current + Δt) % timer.target
    else
      timer.current += Δt
      timer.elapsed = no

export get-progress = (timer) ->
  timer.current / timer.target

export reset = (timer) ->
  timer.current = 0
  timer.elapsed = no
  timer.active = yes

