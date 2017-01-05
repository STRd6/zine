# Explorer File Browser
#
# Explore the file system like adventureres of old!

FileTemplate = require "../templates/file"

module.exports = (options={}) ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI
  {path} = options
  path ?= '/'

  explorer = document.createElement "explorer"

  contextMenuFor = (file, e) ->
    return if e.defaultPrevented
    e.preventDefault()

    # TODO: Open With Options
    # TODO: Set Mime Type
    contextMenu = ContextMenu
      items: parseMenu """
        Hello
        Radical
        -
        Yolo
        -
        Cool
      """
      handlers: {}

    contextMenu.display
        inElement: document.body
        x: e.pageX
        y: e.pageY

  # TODO: Refresh files when they change

  system.fs.list(path)
  .then (files) ->
    files.forEach (file) ->
      file.dblclick = ->
        console.log "dblclick", file
        system.open file

      file.contextmenu = (e) ->
        contextMenuFor(file, e)

      explorer.appendChild FileTemplate file

  return explorer
