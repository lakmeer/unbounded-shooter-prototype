
{ id, log } = require \std


#
# A sound effect loaded from a URL
#

export class Sound

  load-audio = (context, url, λ) ->

    if DEBUG_DISABLE_AUDIO then return λ null, ASSET_LOAD_COMPLETE

    on-decode-audio = (buffer) ->
      if !buffer
        warn "SOMETHING WRONG - can't load #url"
        λ buffer, ASSET_LOAD_FAILED
      else
        λ buffer, ASSET_LOAD_COMPLETE

    on-decode-failed = ->
      log "ERROR DECODING #url"
      λ void, ASSET_LOAD_FAILED

    req = new XMLHttpRequest
    req.open \GET, url, true
    req.response-type = \arraybuffer
    req.onload = ->
      log req.response
      context.decode-audio-data req.response, on-decode-audio, on-decode-failed
    req.onerror = -> λ buffer, ASSET_LOAD_FAILED
    req.send!


  (@url, @ctx, { @volume = 1 } = {}) ->

    log @buffer = @ctx.create-buffer 2, 2, 44100

    load-audio @ctx, @url, (buffer, status) ~>
      if status is ASSET_LOAD_COMPLETE
        @buffer = buffer

  load: (url) ->


