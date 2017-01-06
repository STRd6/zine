# Explorer File Browser
#
# Explore the file system like adventureres of old!
# TODO: Drag and drop files and folders

FileTemplate = require "../templates/file"
FolderTemplate = require "../templates/folder"

{emptyElement} = require "../util"

module.exports = Explorer = (options={}) ->
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
        Open
        Open With
        -
        Cut
        Copy
        -
        Delete
        Rename
        -
        Properties
      """
      handlers:
        open: ->
          system.open(file)
        openWith: -> #TODO
        cut: -> #TODO
        copy: -> #TODO
        delete: ->
          system.deleteFile(file.path)
        rename: ->
          Modal.prompt "Filename", file.path
          .then (newPath) ->
            if newPath
              system.deleteFile(file.path)
              system.writeFile(newPath, file.blob)
        properties: -> #TODO

    contextMenu.display
        inElement: document.body
        x: e.pageX
        y: e.pageY

  contextMenuForFolder = (folder, e) ->
    return if e.defaultPrevented
    e.preventDefault()

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
          addWindow(folder.path)
        delete: -> # TODO: Delete all files under folder
        rename: ->
          ;# TODO: Rename all files under folder (!)
          # May want to think about inodes or something that makes this simpler
        properties: -> # TODO

    contextMenu.display
        inElement: document.body
        x: e.pageX
        y: e.pageY

  update = ->
    system.fs.list(path)
    .then (files) ->
      emptyElement explorer

      addedFolders = {}

      files.forEach (file) ->
        if file.relativePath.match /\// # folder
          folderPath = file.relativePath.replace /\/.*$/, ""
          addedFolders[folderPath] = true
          return

        file.dblclick = ->
          console.log "dblclick", file
          system.open file

        file.contextmenu = (e) ->
          contextMenuFor(file, e)

        explorer.appendChild FileTemplate file

      Object.keys(addedFolders).forEach (folderName) ->
        folder = 
          path: "#{path}#{folderName}/"
          relativePath: folderName
          contextmenu: (e) ->
            contextMenuForFolder(folder, e)
          dblclick: ->
            # Open folder in new window
            addWindow(folder.path)

        folderElement = FolderTemplate folder
        explorer.insertBefore(folderElement, explorer.firstChild)

  update()

  # Refresh files when they change
  system.fs.on "write", (path) ->
    update()
  system.fs.on "delete", (path) ->
    update()

  addWindow = (path) ->
    element = document.createElement "container"

    element.appendChild Explorer
      path: path

    windowView = Window
      title: path
      content: element
      menuBar: null
      width: 640
      height: 480

    document.body.appendChild windowView.element

  return explorer
