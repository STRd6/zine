# Explorer File Browser
#
# Explore the file system like adventureres of old!
# TODO: Drag and drop folders between folders
# TODO: Drop files onto folders
# TODO: Drop files onto applications
# TODO: Select multiple
# TOOD: Keyboard Input

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
    return if e.defaultPrevented

    fileSelectionData = e.dataTransfer.getData("zineos/file-selection")

    if fileSelectionData
      data = JSON.parse fileSelectionData
      system.moveFileSelection(data, path)
      e.preventDefault()

      return

    files = e.dataTransfer.files

    if files.length
      e.preventDefault()
      files.forEach (file) ->
        newPath = path + file.name
        system.writeFile(newPath, file, true)

  explorerContextMenu = ContextMenu
    items: parseMenu """
      [N]ew File
    """
    handlers:
      newFile: ->
        Modal.prompt "Filename", "#{path}newfile.txt"
        .then (newFilePath) ->
          if newFilePath
            system.writeFile newFilePath, new Blob [], type: "text/plain"

  explorer.oncontextmenu = (e) ->
    return if e.defaultPrevented
    e.preventDefault()

    explorerContextMenu.display
      inElement: document.body
      x: e.pageX
      y: e.pageY

  contextMenuFor = (file, e) ->
    return if e.defaultPrevented
    e.preventDefault()

    contextMenuHandlers =
      open: ->
        system.open(file)
      cut: -> #TODO
      copy: -> #TODO
      delete: ->
        system.deleteFile(file.path)
      rename: ->
        Modal.prompt "Filename", file.path
        .then (newPath) ->
          if newPath
            system.moveFile(file.path, newPath)
      properties: ->
        pre = document.createElement "pre"
        pre.textContent = JSON.stringify(file, null, 2)
        pre.style = "padding: 1rem"
        Modal.show pre
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
          system.open file

        file.contextmenu = (e) ->
          contextMenuFor(file, e)

        file.dragstart = (e) ->
          # Note: Blobs don't make it through the stringify
          e.dataTransfer.setData "zineos/file-selection", JSON.stringify
            sourcePath: path
            files: [ file ]

        fileElement = FileTemplate file
        if file.type.match /^image\//
          file.blob.getURL()
          .then (url) ->
            icon = fileElement.querySelector('icon')
            icon.style.backgroundImage = "url(#{url})"
            icon.style.backgroundSize = "100%"
            icon.style.backgroundPosition = "50%"

        explorer.appendChild fileElement

      Object.keys(addedFolders).reverse().forEach (folderName) ->
        folder =
          path: "#{path}#{folderName}/"
          relativePath: folderName
          contextmenu: (e) ->
            contextMenuForFolder(folder, e)
          dblclick: ->
            # Open folder in new window
            addWindow(folder.path)
          dragstart: (e) ->
            console.log e, folder

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
