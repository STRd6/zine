# View and Manipulate Images

FileIO = require "../os/file-io"
Model = require "model"

module.exports = ->
  # Global system
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI

  system.Achievement.unlock "Look at that"

  canvas = document.createElement 'canvas'
  context = canvas.getContext('2d')

  modalForm = system.compileTemplate """
    form
      label
        h2 Width
        input(name="width")
      label
        h2 Height
        input(name="height")
  """

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

    crop: ->
      Modal.form modalForm()
      .then console.log

  menuBar = MenuBar
    items: parseMenu """
      [F]ile
        [O]pen
        [S]ave
        Save [A]s
        -
        E[x]it
      [E]dit
        [C]rop
        [F]ilter
    """
    handlers: handlers

  windowView = Window
    title: "Spectacle Image Viewer"
    content: canvas
    menuBar: menuBar.element
    width: 640
    height: 480

  windowView.loadFile = handlers.loadFile

  return windowView
