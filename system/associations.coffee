AppDrop = require "../lib/app-drop"

# TODO: Move handlers out
AudioBro = require "../apps/audio-bro"
Filter = require "../apps/filter"
Notepad = require "../apps/notepad"
CodeEditor = require "../apps/text-editor"
Explorer = require "../apps/explorer"
Spreadsheet = require "../apps/spreadsheet"
PixelEditor = require "../apps/pixel"
Markdown = require "../apps/markdown"
DSad = require "../apps/dungeon-of-sadness"
MyBriefcase = require "../apps/my-briefcase"

PkgFS = require "../lib/pkg-fs"

{extensionFor} = require "../util"

openWith = (App) ->
  (file) ->
    app = App()

    if file
      {path} = file
      system.readFile path
      .then (blob) ->
        app.loadFile(blob, path)

    system.attachApplication(app)

module.exports = (I, self) ->
  # Handlers use type and contents path info to do the right thing
  # The first handler that matches is the default handler, the rest are available
  # from context menu
  handlers = [{
    name: "Markdown" # TODO: This renders html now too, so may need a broader name
    filter: (file) ->
      file.path.match(/\.md$/) or
      file.path.match(/\.html$/)
    fn: openWith(Markdown) # TODO: This can be a pointer to a system package
  }, {
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
  }, {
    name: "Ace Editor"
    filter: (file) ->
      file.path.match(/\.coffee$/) or
      file.path.match(/\.cson$/) or
      file.path.match(/\.html$/) or
      file.path.match(/\.jadelet$/) or
      file.path.match(/\.js$/) or
      file.path.match(/\.json$/) or
      file.path.match(/\.md$/) or
      file.path.match(/\.styl$/)
    fn: openWith(CodeEditor) # TODO: This can be a pointer to a system package
  }, {
    name: "Run"
    filter: (file) ->
      file.path.match(/💾$/)
    fn: (file) ->
      # TODO: Rename?
      system.execPathWithFile file.path, null
  }, {
    name: "Publish"
    filter: (file) ->
      file.path.match(/💾$/)
    fn: (file) ->
      system.readFile file.path
      .then (blob) ->
        blob.readAsJSON()
      .then (pkg) ->
        system.UI.Modal.prompt "Path", "/My Briefcase/public/somefolder"
        .then (path) ->
          blob = new Blob [system.htmlForPackage(pkg)],
            type: "text/html; charset=utf-8"
          system.writeFile(path + "/index.html", blob)
  }, {
    name: "Run Link"
    filter: (file) ->
      file.path.match(/🔗$|\.link$/)
    fn: (file) ->
      # TODO: Rename?
      system.execPathWithFile file.path, null
  }, {
    name: "Edit Link"
    filter: (file) ->
      file.path.match(/🔗$|\.link$/)
    fn: openWith(CodeEditor)
  }, {
    name: "Sys Exec"
    filter: (file) ->
      return false # TODO: Enable with super mode :P
      file.type is "application/javascript" or
      file.path.match(/\.js$/) or
      file.path.match(/\.coffee$/)
    fn: (file) ->
      self.execute(file.path)
  }, {
    name: "Notepad"
    filter: (file) ->
      file.type.match(/^text\//) or
      file.type.match(/^application\/javascript/)
    fn: openWith(Notepad)
  }, {
    name: "Spreadsheet"
    filter: (file) ->
      # TODO: This actually only handles JSON arrays
      file.type.match(/^application\/json/)
    fn: openWith(Spreadsheet)
  }, {
    name: "Image Viewer"
    filter: (file) ->
      file.type.match /^image\//
    fn: openWith(Filter)
  }, {
    name: "Pixel Editor"
    filter: (file) ->
      file.type.match /^image\//
    fn: openWith(PixelEditor)
  }, {
    name: "PDF Viewer"
    filter: (file) ->
      file.path.match /\.pdf$/
    fn: (file) ->
      file.blob.getURL()
      .then (url) ->
        app = system.iframeApp
          src: url
          title: file.path
        system.attachApplication app
  }, {
    name: "Audio Bro"
    filter: (file) ->
      file.type.match /^audio\//
    fn: openWith(AudioBro)
  }, {
    name: "dsad.exe"
    filter: (file) ->
      file.path.match /dsad\.exe$/
    fn: ->
      app = DSad()
      system.attachApplication app
  }, {
    name: "zine1.exe"
    filter: (file) ->
      file.path.match /zine1\.exe$/
    fn: ->
      require("../issues/2016-12")()
  }, {
    name: "zine2.exe"
    filter: (file) ->
      file.path.match /zine2\.exe$/
    fn: ->
      require("../issues/2017-02")()
  }, {
    name: "zine3.exe"
    filter: (file) ->
      file.path.match /zine3\.exe$/
    fn: ->
      require("../issues/2017-03")()
  }, {
    name: "zine4.exe"
    filter: (file) ->
      file.path.match /zine4\.exe$/
    fn: ->
      require("../issues/2017-04")()
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
      app = MyBriefcase()
      system.attachApplication app
  }]

  # Open JSON arrays in spreadsheet
  # Open text in notepad
  handle = (file) ->
    handler = handlers.find ({filter}) ->
      filter(file)

    if handler
      handler.fn(file)
    else
      throw new Error "No handler for files of type #{file.type}"

  mimes =
    html: "text/html"
    js: "application/javascript"
    json: "application/json"
    md: "text/markdown"

  Object.assign self,
    iframeApp: require "../lib/iframe-app"

    # Open a file
    # TODO: Pass arguments
    # TODO: Drop files on an app to open them in that app
    open: (file) ->
      handle(file)

    openPath: (path) ->
      self.readFile path
      .then self.open

    # Return a list of all handlers that can be used for this file
    openersFor: (file) ->
      handlers.filter (handler) ->
        handler.filter(file)

    # Add a handler to the list of handlers, position zero is highest priority
    # position -1 is lowest priority.
    registerHandler: (handler, position=0) ->
      handlers.splice(position, 0, handler)

    handlers: ->
      handlers.slice()

    # The final step in launching an application in the OS
    # This wires up event streams, drop events, adds the app to the list
    # of running applications, and attaches the app's element to the DOM
    attachApplication: (app, options={}) ->
      # Bind Drop events
      AppDrop(app)

      # TODO: Bind to app event streams

      # TODO: Add to list of apps

      document.body.appendChild app.element

    pathAsApp: (path) ->
      if path.match(/💾$/)
        system.readFile path
        .then (blob) ->
          blob.readAsJSON()
        .then (pkg) ->
          return ->
            self.executePackageInIFrame(pkg)
      else if path.match(/🔗$|\.link$/)
        system.readFile path
        .then (blob) ->
          blob.readAsText()
        .then system.evalCSON
        .then (data) ->
          return ->
            system.iframeApp data
      else if path.match(/\.js$|\.coffee$/)
        self.packageProgram(path)
        .then (pkg) ->
          return ->
            self.executePackageInIFrame pkg
      else
        Promise.reject new Error "Could not launch #{path}"

    execPathWithFile: (path, file) ->
      self.pathAsApp(path)
      .then (App) ->
        openWith(App)(file)

    mimeTypeFor: (path) ->
      mimes[extensionFor(path)] or "text/plain"

  return self
