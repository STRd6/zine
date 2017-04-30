AppDrop = require "../lib/app-drop"
IFrameApp = require "../lib/iframe-app"
FileIO = require "../os/file-io"
Model = require "model"

module.exports = ->
  {MenuBar, Modal, Observable, Util:{parseMenu}} = system.UI

  handlers = Model().include(FileIO).extend
    loadFile: (blob) ->
      app.send "loadFile", blob
    newFile: ->
    saveData: ->
      app.send "getBlob"

  menuBar = MenuBar
    items: parseMenu """
      [F]ile
        [N]ew
        [O]pen
        [S]ave
        Save [A]s
        -
        E[x]it
      [H]elp
        View [H]elp
        -
        [A]bout
    """
    handlers: handlers

  app = IFrameApp
    title: Observable "Pixie Paint"
    src: "https://danielx.net/pixel-editor/"
    menuBar: menuBar
    handlers: handlers
    width: 640
    height: 480

  app.handlers = handlers
  app.loadFile = handlers.loadFile

  system.Achievement.unlock "Pixel perfect"

  AppDrop(app)

  return app
