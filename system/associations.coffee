# TODO: Move handlers out
Filter = require "../apps/filter"
TextEditor = require "../apps/text-editor"
Spreadsheet = require "../apps/spreadsheet"

module.exports = (I, self) ->
  # TODO: Handlers that can use combined type, extension, and contents info
  # to do the right thing
  # Prioritize handlers falling back to others
  handlers = [{
    # JavaScript
    name: "Execute"
    filter: (file) ->
      file.type is "application/javascript"
    fn: (file) ->
      self.include([file.path])
      .then ([moduleExports]) ->
        moduleExports
  }, {
    name: "Open as Text"
    filter: (file) ->
      file.type.match /^text\//
    fn: (file) ->
      editor = TextEditor()
      editor.loadFile(file.blob)
      document.body.appendChild editor.element
  }, {
    name: "Open Spreadsheet"
    filter: (file) ->
      # TODO: This actually only handles JSON arrays
      file.type is "application/json"
    fn: (file) ->
      editor = Spreadsheet()
      editor.loadFile(file.blob)
      document.body.appendChild editor.element
  }, {
    name: "View Image"
    filter: (file) ->
      file.type.match /^image\//
    fn: (file) ->
      app = Filter()
      app.loadFile(file.blob)
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
    # Open a file
    # TODO: Pass arguments
    # TODO: Drop files on an app to open them in that app
    open: (file) ->
      handle(file)

  return self
