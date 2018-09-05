###
IFrameApp loads an app in an iframe and returns a UI window that the system can
use to interact with it.

The apps can be sandboxed by passing in the sandbox option.

Apps are communicated with via `postMessage`

The iframed app is responsible for sending the `ready` message when it is in a
state that can respond to messages from the OS.

###

{Observable} = require "ui"
Postmaster = require "postmaster"

ObservableObject = require "./observable-object"

{version} = require "../pixie"

{absolutizePath, isAbsolutePath} = require "../util"

module.exports = (opts={}) ->
  {Window, Modal} = system.UI

  {achievement, allow, height, menuBar, src, title, width, sandbox, icon:iconEmoji, env} = opts

  env ?=
    pwd: "/"

  # TODO: Trigger achievement from inside iframe :|
  # Or maybe from a watcher on system level app events...
  # Decoupling the cheevos is gonna be a journey
  if achievement
    system.Achievement.unlock achievement

  frame = document.createElement "iframe"

  # Need to allow-modals so apps can show the print view (yes for paper printing!)
  sandbox ?= "allow-modals allow-forms allow-pointer-lock allow-popups allow-scripts allow-popups-to-escape-sandbox"
  if sandbox
    frame.setAttribute("sandbox", sandbox)

  if allow
    frame.setAttribute("allow", allow)

  if src
    frame.src = src

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
      env: env
      args: {} # TODO: Can pass args here, args can be an object

  # TODO: Set menu bar from within app

  # TODO: embalm objects for passing into the afterlife (into iframes)
  embalm = (x) -> x
  # TODO: revitalize embalmed objects that are received
  # these can be used to link observables, or to have proxy objects
  # that remotely invoke their methods and return promises
  revitalize = (x) -> x

  # We use the pwd as the base path for relative paths in the read/write/delete
  # calls for file manipulation. Absolute paths are unchanged.
  resolvePath = (path) ->
    if isAbsolutePath(path)
      absolutizePath "/", path
    else
      absolutizePath env.pwd, path

  systemProxy = new Proxy
    readFile: (path) ->
      system.readFile(resolvePath(path))
    writeFile: (path, blob) ->
      system.writeFile(resolvePath(path), blob)
    deleteFile: (path) ->
      system.deleteFile(resolvePath(path))
    readAsText: (path) ->
      system.readAsText(resolvePath(path))
    readTree: (path) ->
      # TODO: Figure out how to embalm the entries so they can proxy the calls
      system.readTree(resolvePath(path)).then (data) ->
        data.forEach (datum) ->
          delete datum.blob

        return data
  ,
    get: (target, method, receiver) ->
      target[method] or
      (args...) ->
        fn = system[method]
        if typeof fn is "function"
          Promise.resolve(fn.apply(system, revitalize(args)))
          .then embalm
        else
          throw new Error "system has no method '#{method}'"

  # This receives messages from the iframe and dispatches messages to the iframe
  # Apps within ZineOS can communicate to each other via the application object,
  # while within the iframe they communicate through this postmaster degegate to
  # their specific application or the system.
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
      # This is where we receive messages from the client. By default we pass
      # them on to the application object representing the application in the
      # system. Some things we set up specially, like observing signals.
      application: (method, args...) ->
        # Bind to a signal, returning its current value and triggering a call to
        # updateSignal when its value changes.
        if method is "observeSignal"
          name = args[0]
          signals.get(name).observe (newValue) ->
            postmaster.invokeRemote("updateSignal", name, newValue)

          return signals.get(name)()
        else
          application[method](args...)

      # Add system method access to client iFrame
      # TODO: Security :P
      system: (method, args...) ->
        systemProxy[method](args...)

  application = Window
    title: title
    content: frame
    menuBar: menuBar?.element
    width: width
    height: height
    iconEmoji: iconEmoji

  signals = ObservableObject()

  doExit = ->
    setTimeout ->
      application.element.remove()
      application.trigger "exit"
    , 0

  Object.assign application,
    # Observable fn that returns an array of [key, Observable(value)] items
    signals: signals
    # Expose an observable property that can be updated from within the iframe
    setSignal: signals.set
    saved: Observable true
    exit: ->
      # Prompt unsaved, etc.
      if application.saved()
        doExit()
      else
        Modal.confirm "You will lose unsaved changes"
        .then (ok) ->
          if ok
            doExit()

      return

    # Send a message into the iframe, received by the client's postmaster.delegate
    send: (method, args...) ->
      loadedPromise.then ->
        postmaster.invokeRemote method, args...

  return application
