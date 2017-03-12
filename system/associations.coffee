# TODO: Move handlers out
AudioBro = require "../apps/audio-bro"
Filter = require "../apps/filter"
Notepad = require "../apps/notepad"
CodeEditor = require "../apps/text-editor"
Spreadsheet = require "../apps/spreadsheet"
PixelEditor = require "../apps/pixel"
Markdown = require "../apps/markdown"
DSad = require "../apps/dungeon-of-sadness"

openWith = (App) ->
  (file) ->
    app = App()
    app.loadFile(file.blob, file.path)
    document.body.appendChild app.element

module.exports = (I, self) ->
  # TODO: Handlers that can use combined type, extension, and contents info
  # to do the right thing
  # Prioritize handlers falling back to others
  handlers = [{
    # JavaScript
    name: "Execute"
    filter: (file) ->
      file.type is "application/javascript" or
      file.path.match /\.js$/
    fn: (file) ->
      file.blob.readAsText()
      .then (sourceProgram) ->
        system.loadModule sourceProgram, file.path
  }, {
    # CoffeeScript
    name: "Execute"
    filter: (file) ->
      file.path.match /\.coffee$/
    fn: (file) ->
      file.blob.readAsText()
      .then (coffeeSource) ->
        sourceProgram = CoffeeScript.compile coffeeSource, bare: true

        system.loadModule sourceProgram, file.path
  }, {
    name: "Markdown"
    filter: (file) ->
      file.path.match /\.md$/
    fn: openWith(Markdown)
  }, {
    name: "Text Editor"
    filter: (file) ->
      file.type.match(/^text\//) or
      file.type is "application/javascript"
    fn: openWith(Notepad)
  }, {
    name: "Code Editor"
    filter: (file) ->
      file.path.match(/\.coffee$/) or
      file.path.match(/\.js$/)
    fn: openWith(CodeEditor)
  }, {
    name: "Spreadsheet"
    filter: (file) ->
      # TODO: This actually only handles JSON arrays
      file.type is "application/json"
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
    # Open a file
    # TODO: Pass arguments
    # TODO: Drop files on an app to open them in that app
    open: (file) ->
      handle(file)

    openersFor: (file) ->
      handlers.filter (handler) ->
        handler.filter(file)

  return self
