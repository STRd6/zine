# Explorer File Browser
#
# Explore the file system like adventureres of old!

# TODO: Select multiple
# TOOD: Keyboard Input

Drop = require "../lib/drop"
FileTemplate = require "../templates/file"
FolderTemplate = require "../templates/folder"

{emptyElement} = require "../util"

extractPath = (element) ->
  while element
    path = element.getAttribute("path")
    return path if path
    element = element.parentElement

module.exports = Explorer = (options={}) ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI
  {path} = options
  path ?= '/'

  explorer = document.createElement "explorer"
  explorer.setAttribute("path", path)

  Drop explorer, (e) ->
    return if e.defaultPrevented

    targetPath = extractPath(e.target) or path
    folderTarget = targetPath.match(/\/$/)

    fileSelectionData = e.dataTransfer.getData("zineos/file-selection")

    if fileSelectionData
      data = JSON.parse fileSelectionData

      if folderTarget
        system.moveFileSelection(data, targetPath)
      else
        # Attempt to open file in app
        selectedFile = data.files[0]
        console.log "Open in app #{targetPath} <- #{selectedFile}"
        system.readFile(selectedFile.path)
        .then (file) ->
          system.launchAppByPath(targetPath, file.path)
      e.preventDefault()

      return

    files = e.dataTransfer.files

    if files.length
      e.preventDefault()
      if folderTarget
        files.forEach (file) ->
          newPath = targetPath + file.name
          system.writeFile(newPath, file, true)
      else
        file = files[0]
        system.launchAppByPath(targetPath, file.path)

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
        delete: ->
          system.readTree(folder.path)
          .then (results) ->
            Promise.all results.map (result) ->
              system.deleteFile(result.path)
        rename: ->
          Modal.prompt "Name", folder.path
          .then (newName) ->
            return unless newName

            # Ensure trailing slash
            newName = newName.replace(/\/*$/, "/")

            system.readTree(folder.path)
            .then (files) ->
              Promise.all files.map (file) ->
                newPath = file.path.replace(folder.path, newName)
                system.moveFile(file.path, newPath)
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
        if file.relativePath.match /\/$/ # folder
          folderPath = file.relativePath
          addedFolders[folderPath] = true
          return

        Object.assign file,
          displayName: file.relativePath

          dblclick: ->
            system.open file

          contextmenu: (e) ->
            contextMenuFor(file, e)

          dragstart: (e) ->
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
          path: "#{path}#{folderName}"
          relativePath: folderName
          displayName: folderName.replace(/\/$/, "")
          contextmenu: (e) ->
            contextMenuForFolder(folder, e)
          dblclick: ->
            # Open folder in new window
            addWindow(folder.path)
          dragstart: (e) ->
            e.dataTransfer.setData "zineos/file-selection", JSON.stringify
              sourcePath: folder.path.slice(0, folder.path.length - folder.relativePath.length)
              files: [ folder ]

        folderElement = FolderTemplate folder
        explorer.insertBefore(folderElement, explorer.firstChild)

  update()

  # Refresh files when they change
  system.fs.on "write", (path) -> update()
  system.fs.on "delete", (path) -> update()
  system.fs.on "update", (path) -> update()

  addWindow = (path) ->
    element = Explorer
      path: path

    windowView = Window
      title: path
      content: element
      menuBar: null
      width: 640
      height: 480
      iconEmoji: "📂"

    document.body.appendChild windowView.element

  return explorer
