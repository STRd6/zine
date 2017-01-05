Model = require "model"
FileIO = require "../os/file-io"

ace.require("ace/ext/language_tools")

extraModes =
  jadelet: "jade"

mode = (mode) ->
  extraModes[mode] or mode

module.exports = ->
  {ContextMenu, MenuBar, Modal, Observable, Progress, Table, Util:{parseMenu}, Window} = system.UI

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

  initSession = (file) ->
    # TODO: Update window title
    file.readAsText()
    .then (content) ->
      session.setValue(content)
      # TODO: Correct modes
      mode = "coffee"
      session.setMode("ace/mode/#{mode}")

  handlers = Model().include(FileIO).extend
    loadFile: initSession
    newFile: ->
      session.setValue ""
    saveData: ->
      # TODO: Maintain proper mime type
      data = new Blob [session.getValue()],
        type: "text/plain"

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
    title: Observable "Ace"
    content: aceWrap
    menuBar: menuBar.element
    width: 640
    height: 480

  windowView.loadFile = initSession

  windowView.on "resize", ->
    aceEditor.resize()

  return windowView
