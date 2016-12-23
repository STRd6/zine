UI = require "ui"

module.exports = () ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = UI

  exec = (cmd) -> 
    ->
      textarea.focus()
      document.execCommand(cmd)

  TODO = -> console.log "TODO"

  textarea = document.createElement "textarea"

  menuBar = MenuBar
    items: parseMenu """
      [F]ile
        [N]ew
        [O]pen
        [S]ave
        Save [A]s
        -
        Page Set[u]p
        [P]rint
        -
        E[x]it
      [E]dit
        [U]ndo
        Redo
        -
        Cu[t]
        [C]opy
        [P]aste
        De[l]ete
        -
        [F]ind
        Find [N]ext
        [R]eplace
        [G]o To
        -
        Select [A]ll
        Time/[D]ate
      F[o]rmat
        [W]ord Wrap
        [F]ont...
      [V]iew
        [S]tatus Bar
      [H]elp
        View [H]elp
        -
        [A]bout Notepad
    """
    handlers:
      new: ->
      open: ->
      save: ->
      saveAs: ->
      pageSetup: TODO
      print: TODO
      exit: ->
        windowView.element.remove()
      undo: exec "undo"
      redo: exec "redo"
      cut: exec "cut"
      copy: exec "copy"
      paste: exec "paste"
      delete: exec "delete"
      find: TODO
      findNext: TODO
      replace: TODO
      goTo: TODO
      selectAll: -> 
        textarea.select()
      timeDate: ->
        textarea.focus()
        dateText = (new Date).toString().split(" ").slice(0, -4).join(" ")
        document.execCommand("insertText", false, dateText)
      wordWrap: TODO
      font: TODO
      statusBar: TODO
      viewHelp: TODO
      aboutNotepad: TODO

  windowView = Window
    title: "ZineOS Volume 1 | Issue 1 | December 2016"
    content: textarea
    menuBar: menuBar.element
    width: 640
    height: 480

  return windowView
