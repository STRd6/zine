# TODO: Move handlers out
AudioBro = require "../apps/audio-bro"
Filter = require "../apps/filter"
Notepad = require "../apps/notepad"
CodeEditor = require "../apps/text-editor"
Spreadsheet = require "../apps/spreadsheet"
PixelEditor = require "../apps/pixel"
Markdown = require "../apps/markdown"
DSad = require "../apps/dungeon-of-sadness"
MyBriefcase = require "../apps/my-briefcase"

openWith = (App) ->
  (file) ->
    {path} = file
    app = App()

    system.readFile file.path
    .then (blob) ->
      app.loadFile(blob, path)

    document.body.appendChild app.element

module.exports = (I, self) ->
  # Handlers use combined type, extension, and contents info to do the right thing
  # The first handler that matches is the default handler, the rest are available
  # from context menu
  handlers = [{
    name: "Ace Editor"
    filter: (file) ->
      file.path.match(/\.coffee$/) or
      file.path.match(/\.cson$/) or
      file.path.match(/\.html$/) or
      file.path.match(/\.js$/) or
      file.path.match(/\.json$/) or
      file.path.match(/\.md$/) or
      file.path.match(/\.styl$/)
    fn: openWith(CodeEditor)
  }, {
    # JavaScript
    name: "Execute"
    filter: (file) ->
      file.type is "application/javascript" or
      file.path.match /\.js$/
    fn: (file) ->
      file.blob.readAsText()
      .then (sourceProgram) ->
        system.spawn sourceProgram, file.path
  }, {
    # CoffeeScript
    name: "Execute"
    filter: (file) ->
      file.path.match /\.coffee$/
    fn: (file) ->
      file.blob.readAsText()
      .then (coffeeSource) ->
        sourceProgram = CoffeeScript.compile coffeeSource, bare: true

        system.spawn sourceProgram, file.path
  }, {
    name: "Markdown" # TODO: This renders html now too, so may need a broader name
    filter: (file) ->
      file.path.match(/\.md$/) or
      file.path.match(/\.html$/)
    fn: openWith(Markdown)
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
      document.body.appendChild app.element
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
      document.body.appendChild app.element
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

  Object.assign self,
    iframeApp: require "../lib/iframe-app"

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

    handlers: ->
      handlers.slice()

  return self
