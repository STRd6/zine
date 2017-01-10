# Render Markdown

FileIO = require "../os/file-io"
Model = require "model"

module.exports = ->
  # Global system
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI

  container = document.createElement 'container'
  container.style.padding = "1em"

  handlers = Model().include(FileIO).extend
    loadFile: (blob) ->
      blob.readAsText()
      .then (textContent) ->
        container.innerHTML = marked(textContent)

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
    content: container
    menuBar: menuBar.element
    width: 640
    height: 480

  windowView.loadFile = handlers.loadFile

  return windowView
