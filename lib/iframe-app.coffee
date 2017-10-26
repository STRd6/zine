###
IFrameApp loads an app in an iframe and returns a UI window that the system can
use to interact with it.

The apps can be sandboxed by passing in the sandbox option.

Apps can be loaded from a json package or from a source url.

Apps are communicated with via `postMessage`

The iframed app is responsible for sending the `ready` message when it is in a
state that can respond to messages from the OS.

###

Postmaster = require "postmaster"

{version} = require "../pixie"

module.exports = (opts={}) ->
  {Window, Modal} = system.UI

  {achievement, height, menuBar, src, title, width, sandbox, pkg, packageOptions, iconEmoji} = opts

  # TODO: Trigger achievement from inside iframe :|
  # Or maybe from a watcher on system level app events...
  # Decoupling the cheevos is gonna be a journey
  if achievement
    system.Achievement.unlock achievement

  frame = document.createElement "iframe"

  sandbox ?= "allow-forms allow-pointer-lock allow-popups allow-scripts"
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

  acceptClient = ->
    resolveLoaded()
    loaded = true

    ZineOS:
      version: version
      env: {} # TODO: Can pass env vars here
      args: {} # TODO: Can pass args here, args can be an object

  # TODO: Set menu bar from within app

  # This receives and dispatches the messages from the iframe
  Object.assign postmaster,
    remoteTarget: ->
      frame.contentWindow
    delegate:
      ready: (clientData) ->
        console.info clientData
        acceptClient()

      # Deprecated: should be moved to 'ready'
      childLoaded: ->
        console.warn "'childLoaded' is deprecated call 'ready' instead"
        acceptClient()

      # Send events from the iframe app to the application
      event: ->
        application.trigger "event", arguments...

        return

      # Add application method access to client iFrame
      application: (method, args...) ->
        applicationProxy[method](args...)

      # Add system method access to client iFrame
      # TODO: Security :P
      system: (method, args...) ->
        system[method](args...)

  application = Window
    title: title
    content: frame
    menuBar: menuBar?.element
    width: width
    height: height
    iconEmoji: iconEmoji

  modules =
    FileIO: require "../os/file-io"
  
  # TODO: This dr frankenstein's proxy is a bit too complicated
  applicationProxy = new Proxy application,
    get: (target, property, receiver) ->
      target[property] or
      ->
        application.send property, arguments...

  Object.assign applicationProxy,
    exit: ->
      # TODO: Prompt unsaved, etc.
      setTimeout ->
        application.element.remove()
      , 0
      return

    # Extend the system application interface by including modules
    # So far only FileIO exists, but there may be more in the future
    loadModule: (name) ->
      module = modules[name]
      if module
        # TODO: Shoould applications support `.include(module)`?
        module null, applicationProxy
        return name
      else
        throw new Error "Module '#{name}' not found."

    # Here we weirdly fuse together the local and remote interface
    # If the method exists on our host object invoke that, otherwise send it to
    # the client frame
    send: (method, args...) ->
      loadedPromise.then ->
        if typeof application[method] is 'function'
          application[method](args...)
        else
          postmaster.invokeRemote method, args...

  return applicationProxy
