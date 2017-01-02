Model = require "model"
Postmaster = require "postmaster"
FileIO = require "../os/file-io"

module.exports = ->
  {ContextMenu, MenuBar, Modal, Observable, Progress, Table, Util:{parseMenu}, Window} = system.UI

  frame = document.createElement "iframe"
  frame.src = "https://danielx.net/pixel-editor/"

  postmaster = Postmaster()
  postmaster.remoteTarget = -> frame.contentWindow
  Object.assign postmaster,
    childLoaded: -> 
      console.log "child loaded"
    save: ->
      handlers.save()

  handlers = Model().include(FileIO).extend
    loadFile: ->
    newFile: ->
    saveData: ->
      postmaster.invokeRemote "getBlob"

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

  windowView = Window
    title: Observable "Pixie Paint"
    content: frame
    menuBar: menuBar.element
    width: 640
    height: 480

  return windowView
