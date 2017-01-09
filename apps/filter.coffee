# Filter Images

FileIO = require "../os/file-io"
Model = require "model"

module.exports = ->
  # Global system
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI

  canvas = document.createElement 'canvas'
  context = canvas.getContext('2d')

  handlers = Model().include(FileIO).extend
    loadFile: (blob) ->
      Image.fromBlob blob
      .then (img) ->
        canvas.width = img.width
        canvas.height = img.height
        context.drawImage(img, 0, 0)

    saveData: ->
      new Promise (resolve) ->
        canvas.toBlob resolve

    exit: ->
      windowView.element.remove()

  menuBar = MenuBar
    items: parseMenu """
      [F]ile
        [O]pen
        [S]ave
        Save [A]s
        -
        E[x]it
    """
    handlers: handlers

  windowView = Window
    title: "Filter Booth"
    content: canvas
    menuBar: menuBar.element
    width: 640
    height: 480

  windowView.loadFile = handlers.loadFile

  return windowView
