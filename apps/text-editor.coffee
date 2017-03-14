Model = require "model"
FileIO = require "../os/file-io"

ace.require("ace/ext/language_tools")

extraModes =
  jadelet: "jade"

mode = (mode) ->
  extraModes[mode] or mode

module.exports = ->
  {ContextMenu, MenuBar, Modal, Observable, Progress, Table, Util:{parseMenu}, Window} = system.UI

  system.Achievement.unlock "Notepad.exe"

  aceWrap = document.createElement "div"
  aceWrap.style.width = aceWrap.style.height = "100%"

  aceElement = document.createElement "div"
  aceElement.style.width = aceElement.style.height = "100%"

  aceWrap.appendChild aceElement

  aceEditor = ace.edit aceElement
  aceEditor.$blockScrolling = Infinity
  aceEditor.setOptions
    fontSize: "16px"
    enableBasicAutocompletion: true
    enableLiveAutocompletion: true
    highlightActiveLine: true

  session = aceEditor.getSession()
  session.setUseSoftTabs true
  session.setTabSize 2

  mode = "coffee"
  session.setMode("ace/mode/#{mode}")

  global.aceEditor = aceEditor

  extensionFor = (path) ->
    result = path.match /\.(.+)$/

    if result
      result[1]

  modes =
    cson: "coffeescript"
    jadelet: "jade"
    js: "javascript"
    md: "markdown"
    styl: "stylus"

  mimes =
    html: "text/html"
    js: "application/javascript"
    json: "application/json"
    md: "text/markdown"

  mimeTypeFor = (path) ->
    type = mimes[extensionFor(path)] or "text/plain"

    "#{type}; charset=utf-8"

  setModeFor = (path) ->
    extension = extensionFor(path)
    mode = modes[extension] or extension

    session.setMode("ace/mode/#{mode}")

  initSession = (file, path) ->
    file.readAsText()
    .then (content) ->
      if path
        handlers.currentPath path
        setModeFor(path)

      session.setValue(content)
      handlers.saved true

  session.on "change", ->
    handlers.saved false

  handlers = Model().include(FileIO).extend
    loadFile: initSession
    newFile: ->
      session.setValue ""
    saveData: ->
      data = new Blob [session.getValue()],
        type: mimeTypeFor(handlers.currentPath())

      return Promise.resolve data

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
    title: ->
      path = handlers.currentPath()
      if handlers.saved()
        savedIndicator = ""
      else
        savedIndicator = "*"

      if path
        path = " - #{path}"

      "Ace#{path}#{savedIndicator}"

    content: aceWrap
    menuBar: menuBar.element
    width: 640
    height: 480

  windowView.loadFile = initSession

  windowView.on "resize", ->
    aceEditor.resize()

  # Key handling
  windowView.element.setAttribute("tabindex", "-1")
  windowView.element.addEventListener "keydown", (e) ->
    {ctrlKey:ctrl, key} = e
    if ctrl
      switch key
        when "s"
          e.preventDefault()
          handlers.save()
        when "o"
          e.preventDefault()
          handlers.open()

  return windowView
