
{ id, log } = require \std


# Global Audio Engine houses the single AudioContext used to generate sources

export class AudioOutput

  # X-browser AudioContext
  AudioCtx = AudioContext

  # TODO: Modernizr
  #   if Modernizr.webaudio
  #     if window.AudioContext? then that else if window.webkitAudioContext? then that
  #   else
  #     class FakeAudioContext

  # Global default AudioContext
  context = new AudioCtx

  ->
    @buffer-list    = {}

  add-sound: (url, λ) ->
    load-audio context, url, (buffer, state) ~>
      @buffer-list[url] = buffer
      λ buffer, state

  get-context: ->
    context

  get-buffer-with-url: (url) ->
    @buffer-list[url]

  create-buffer-source: ->
    context.create-buffer-source!

  create-gain-node: ->
    context.create-gain!

  get-destination: ->
    context.destination

  play: (sound) ->
    source = context.create-buffer-source!
    source.buffer = sound.buffer

    gain = context.create-gain!
    gain.gain.value = sound.volume

    source.connect gain
    gain.connect context.destination
    source.start!

  @Null =
    add-sound: id
    get-buffer-with-url: id
    create-buffer-source: id
    create-gain-node: id
    get-destination: id

