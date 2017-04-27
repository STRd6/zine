Drop = require "../lib/drop"
Model = require "model"
Postmaster = require "postmaster"
FileIO = require "../os/file-io"

module.exports = ->
  {ContextMenu, MenuBar, Modal, Observable, Progress, Table, Util:{parseMenu}, Window} = system.UI

  frame = document.createElement "iframe"
  frame.src = "https://danielx.net/pixel-editor/"

  # TODO: Gross hack to keep track of waiting for child window to load
  # May want to move it into the postmaster library
  resolveLoaded = null
  loadedPromise = new Promise (resolve) ->
    resolveLoaded = resolve

  postmaster = Postmaster()
  postmaster.remoteTarget = -> frame.contentWindow
  Object.assign postmaster,
    childLoaded: ->
      console.log "child loaded"
      resolveLoaded()
    save: ->
      handlers.save()

  handlers = Model().include(FileIO).extend
    loadFile: (blob) ->
      loadedPromise.then ->
        postmaster.invokeRemote "loadFile", blob
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

  windowView.loadFile = handlers.loadFile

  system.Achievement.unlock "Pixel perfect"

  # TODO: Extract this to a general drop2app thing
  Drop windowView.element, (e) ->
    fileSelectionData = e.dataTransfer.getData("zineos/file-selection")

    if fileSelectionData
      data = JSON.parse(fileSelectionData)
      e.preventDefault()
      file = data.files[0]

      # TODO: Handle multi-files
      path = data.files[0].path

      system.readFile path
      .then handlers.loadFile
      .then ->
        handlers.currentPath path

      return

  return windowView
