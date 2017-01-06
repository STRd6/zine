# Explorer File Browser
#
# Explore the file system like adventureres of old!

FileTemplate = require "../templates/file"

{emptyElement} = require "../util"

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
    # TODO: Cut/Copy
    contextMenu = ContextMenu
      items: parseMenu """
        Open
        -
        Delete
        Rename
        -
        Properties
      """
      handlers:
        open: ->
          system.open(file)
        delete: ->
        rename: ->
          Modal.prompt "Filename", file.path
          .then (newPath) ->
            if newPath
              system.deleteFile(file.path)
              system.writeFile(newPath, file.blob)

    contextMenu.display
        inElement: document.body
        x: e.pageX
        y: e.pageY

  update = ->
    system.fs.list(path)
    .then (files) ->
      emptyElement explorer

      files.forEach (file) ->
        file.dblclick = ->
          console.log "dblclick", file
          system.open file

        file.contextmenu = (e) ->
          contextMenuFor(file, e)

        explorer.appendChild FileTemplate file

  update()

  # Refresh files when they change
  system.fs.on "write", (path) ->
    update()
  system.fs.on "delete", (path) ->
    update()

  return explorer
