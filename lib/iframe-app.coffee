###
IFrameApp loads an app in an iframe and returns a UI window that the system can
use to interact with it.

The apps can be sandboxed by passing in the sandbox option.

Apps can be loaded from a json package or from a source url.

Apps are communicated with via `postMessage`

###

Model = require "model"
Postmaster = require "postmaster"
FileIO = require "../os/file-io"

{version} = require "../pixie"

module.exports = (opts={}) ->
  {Window} = system.UI

  {height, menuBar, src, handlers, title, width, sandbox, pkg, packageOptions, iconEmoji} = opts

  frame = document.createElement "iframe"

  if sandbox
    frame.setAttribute("sandbox", sandbox)

  if src
    frame.src = src
  else if pkg
    html = system.htmlForPackage(pkg, packageOptions)
    blob = new Blob [html],
      type: "text/html; charset=utf-8"
    frame.src = URL.createObjectURL blob

  # Keep track of waiting for child window to load, all remote invocations are
  # queued behind a promise until the child has loaded
  # May want to move it into the postmaster library
  resolveLoaded = null
  loadedPromise = new Promise (resolve) ->
    resolveLoaded = resolve

  loaded = false
  setTimeout ->
    console.warn "Child never loaded" unless loaded
  , 5000

  # Attach a postmaster to receive events from the child frame
  postmaster = Postmaster()

  Object.assign postmaster,
    remoteTarget: ->
      frame.contentWindow

    childLoaded: ->
      console.log "child loaded"
      resolveLoaded()
      loaded = true

      ZineOS:
        version: version
        env: {} # TODO: Can pass env vars here
        args: {} # TODO: Can pass args here, args can be an object

    # Send events from the iframe app to the application
    event: ->
      application.trigger "event", arguments...

      return

    # Add application method access to client iFrame
    application: (method, args...) ->
      application[method](args...)

    # Add system method access to client iFrame
    # TODO: Security :P
    system: (method, args...) ->
      system[method](args...)

  handlers ?= Model().include(FileIO).extend
    loadFile: (blob) ->
      loadedPromise.then ->
        postmaster.invokeRemote "loadFile", blob
        .catch (e) ->
          console.error "invokeRemote 'loadFile' failed", e

  application = Window
    title: title
    content: frame
    menuBar: menuBar?.element
    width: width
    height: height
    iconEmoji: iconEmoji

  Object.assign application,
    exit: ->
      # TODO: Prompt unsaved, etc.
      setTimeout ->
        application.element.remove()
      , 0
      return
    handlers: handlers
    loadFile: handlers.loadFile
    send: (args...) ->
      loadedPromise.then ->
        postmaster.invokeRemote args...

  return application
