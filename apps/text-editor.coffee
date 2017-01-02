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

  global.aceEditor = aceEditor

  initSession: (file) ->
    session = ace.createEditSession(file.content())

    session.setMode("ace/mode/#{mode file.mode()}")

    session.setUseSoftTabs true
    session.setTabSize 2

    return session

  handlers = Model().include(FileIO).extend
    loadFile: (blob) ->
      blob.readAsText()
      .then (text) ->
        textarea.value = text
    newFile: ->
      textarea.value = ""
    saveData: ->
      data = new Blob [textarea.value],
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
    title: "Notepad.exe"
    content: aceWrap
    menuBar: menuBar.element
    width: 640
    height: 480

  windowView.on "resize", ->
    aceEditor.resize()

  return windowView
