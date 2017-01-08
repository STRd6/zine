# Explorer File Browser
#
# Explore the file system like adventureres of old!
# TODO: Drag and drop files and folders
# TODO: Select multiple
# TOOD: Keyboard Input
# TODO: Style file types

Drop = require "../lib/drop"
FileTemplate = require "../templates/file"
FolderTemplate = require "../templates/folder"

{emptyElement} = require "../util"

module.exports = Explorer = (options={}) ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI
  {path} = options
  path ?= '/'

  explorer = document.createElement "explorer"

  Drop explorer, (e) ->
    files = e.dataTransfer.files

    if files.length
      files.forEach (file) ->
        newPath = path + file.name
        system.writeFile(newPath, file)

  contextMenuFor = (file, e) ->
    return if e.defaultPrevented
    e.preventDefault()

    contextMenuHandlers =
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
      editMIMEType: ->
        Modal.prompt "MIME Type", file.type
        .then (newType) ->
          if newType
            system.updateFile file.path,
              type: newType
            .then console.log

    openers = system.openersFor(file)

    openerOptions = openers.map ({name, fn}, i) ->
      handlerName = "opener#{i}"
      contextMenuHandlers[handlerName] = ->
        fn(file)

      "  #{name} -> #{handlerName}"
    .join("\n")

    openWithMenu = ""
    if openers.length > 0
      openWithMenu = """
        Open With
        #{openerOptions}
      """

    # TODO: Open With Options
    # TODO: Set Mime Type
    contextMenu = ContextMenu
      items: parseMenu """
        Open
        #{openWithMenu}
        -
        Cut
        Copy
        -
        Delete
        Rename
        -
        Edit MIME Type
        Properties
      """
      handlers: contextMenuHandlers
        

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

        fileElement = FileTemplate file
        if file.type.match /^image\//
          url = URL.createObjectURL file.blob
          fileElement.querySelector('icon').style.backgroundImage = "url(#{url})"

        explorer.appendChild fileElement

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
  system.fs.on "write", (path) -> update()
  system.fs.on "delete", (path) -> update()
  system.fs.on "update", (path) -> update()

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
