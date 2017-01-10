# Render Markdown

FileIO = require "../os/file-io"
Model = require "model"

module.exports = ->
  # Global system
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI

  canvas = document.createElement 'div'

  handlers = Model().include(FileIO).extend
    loadFile: (blob) ->
      blob.readAsText()
      .then (textContent) ->
        canvas.innerHTML = marked(textContent)

    saveData: ->

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
    title: "Markdown"
    content: canvas
    menuBar: menuBar.element
    width: 640
    height: 480

  windowView.loadFile = handlers.loadFile

  return windowView
