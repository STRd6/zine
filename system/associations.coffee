# TODO: Move handlers out
AudioBro = require "../apps/audio-bro"
Explorer = require "../apps/explorer"

PkgFS = require "../lib/pkg-fs"

openWith = (App) ->
  (file) ->
    app = App()

    if file
      {path} = file
      system.readFile path
      .then (blob) ->
        app.send "loadFile", blob, path

    system.attachApplication(app)

module.exports = (I, self) ->
  # Handlers use type and contents path info to do the right thing
  # The first handler that matches is the default handler, the rest are available
  # from context menu
  handlers = [{
    name: "Run"
    filter: (file) ->
      file.type is "application/javascript" or
      file.path.match(/\.js$/) or
      file.path.match(/\.coffee$/)
    fn: (file) ->
      self.executeInIFrame(file.path)
  }, {
    name: "Exec"
    filter: (file) ->
      file.type is "application/javascript" or
      file.path.match(/\.js$/) or
      file.path.match(/\.coffee$/)
    fn: (file) ->
      self.execute(file.path)
  }, {
    name: "Explore"
    filter: (file) ->
      file.path.match(/💾$/) or
      file.path.match(/\.json$/)
    fn: (file) ->
      system.readFile(file.path)
      .then (blob) ->
        blob.readAsJSON()
      .then (pkg) ->
        mountPath = file.path + "/"
        fs = PkgFS(pkg, file.path)
        system.fs.mount mountPath, fs

        # TODO: Can we make the explorer less specialized here?
        element = Explorer
          path: mountPath
        windowView = system.UI.Window
          title: mountPath
          content: element
          menuBar: null
          width: 640
          height: 480
          iconEmoji: "📂"

        document.body.appendChild windowView.element
  },{
    name: "Run Link"
    filter: (file) ->
      file.path.match(/🔗$|\.link$/)
    fn: (file) ->
      # TODO: Rename?
      system.execPathWithFile file.path, null
  }, {
    name: "PDF Viewer"
    filter: (file) ->
      file.path.match /\.pdf$/
    fn: (file) ->
      file.getURL()
      .then (url) ->
        app = system.iframeApp
          src: url
          sandbox: false # Need Chrome's pdf plugin to view pdfs
          title: file.path
        system.attachApplication app
  }, {
    name: "Audio Bro"
    filter: (file) ->
      file.type.match /^audio\//
    fn: openWith(AudioBro)
  }, {
    name: "feedback.exe"
    filter: (file) ->
      file.path.match /feedback\.exe$/
    fn: ->
      require("../feedback")()
  }, {
    name: "My Briefcase"
    filter: ({path}) ->
      path.match /My Briefcase$/
    fn: ->
      system.openBriefcase()
  },{
    name: "Run Application"
    filter: (file) ->
      file.type is "application/json" and
      file.path.match(/\.exe$/)
    fn: (file) ->
      system.execPathWithFile file.path, null
  }]

  handle = (file) ->
    handler = handlers.find ({filter}) ->
      filter(file)

    if handler
      handler.fn(file)
    else
      throw new Error "No handler for files of type #{file.type}"

  Object.assign self,
    # Open a file
    # TODO: Pass arguments
    # TODO: Drop files on an app to open them in that app
    open: (file) ->
      handle(file)

    # Return a list of all handlers that can be used for this file
    openersFor: (file) ->
      handlers.filter (handler) ->
        handler.filter(file)

    # Add a handler to the list of handlers, position zero is highest priority
    # position -1 is lowest priority.
    registerHandler: (handler, position=0) ->
      handlers.splice(position, 0, handler)

    removeHandler: (handler) ->
      position = handlers.indexOf(handler)
      if position >= 0
        handlers.splice(position, 1)
        return handler

      return

    handlers: ->
      handlers.slice()

  return self
