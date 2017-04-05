Model = require "model"
Postmaster = require "postmaster"
FileIO = require "../os/file-io"

module.exports = (opts={}) ->
  {ContextMenu, MenuBar, Modal, Observable, Progress, Table, Util:{parseMenu}, Window} = system.UI

  {height, menuBar, src, title, width, sandbox, pkg} = opts

  frame = document.createElement "iframe"

  if sandbox
    frame.setAttribute("sandbox", sandbox)

  if src
    frame.src = src
  else if pkg
    frame.src = URL.createObjectURL new Blob ["""
      <html>
        <head>
          <meta charset="utf-8">
        </head>
        <body>
        <script>
          #{require.executePackageWrapper(pkg)}
        <\/script>
        </body>
      </html>
    """], type: "text/html; charset=utf-8"

  # Keep track of waiting for child window to load, all remote invocations are
  # queued behind a promise until the child has loaded
  # May want to move it into the postmaster library
  resolveLoaded = null
  loadedPromise = new Promise (resolve) ->
    resolveLoaded = resolve

  # Attach a postmaster to receive events from the child frame
  postmaster = Postmaster()
  postmaster.remoteTarget = -> frame.contentWindow
  Object.assign postmaster,
    childLoaded: ->
      console.log "child loaded"
      resolveLoaded()

    # Send events from the iframe app to the window view
    event: ->
      windowView.trigger "event", arguments...

      return

  # TODO: Extend with passed in handlers?
  handlers = Model().include(FileIO).extend
    loadFile: (blob) ->
      loadedPromise.then ->
        postmaster.invokeRemote "loadFile", blob

  windowView = Window
    title: title
    content: frame
    menuBar: menuBar?.element
    width: width
    height: height

  windowView.loadFile = handlers.loadFile

  return windowView