# Play Audio

FileIO = require "../os/file-io"
Model = require "model"

module.exports = ->
  # Global system
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI

  audio = document.createElement 'audio'
  audio.controls = true
  audio.autoplay = true

  handlers = Model().include(FileIO).extend
    loadFile: (blob) ->
      audio.src = URL.createObjectURL blob

    exit: ->
      windowView.element.remove()

  menuBar = MenuBar
    items: parseMenu """
      [F]ile
        [O]pen
        -
        E[x]it
    """
    handlers: handlers

  windowView = Window
    title: "Audio Bro"
    content: audio
    menuBar: menuBar.element
    width: 640
    height: 480

  windowView.loadFile = handlers.loadFile

  return windowView
