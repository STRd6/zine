Drop = require "./drop"

# General drop handling for apps
module.exports = (app) ->
  {element} = app

  Drop element, (e) ->
    {handlers} = app

    fileSelectionData = e.dataTransfer.getData("zineos/file-selection")

    if fileSelectionData
      data = JSON.parse(fileSelectionData)
      e.preventDefault()
      file = data.files[0]

      # TODO: Handle multi-files
      path = data.files[0].path

      system.readFile path
      .then handlers.loadFile
      .then ->
        handlers.currentPath path

      return

    files = e.dataTransfer.files

    if files.length
      e.preventDefault()

      file = files[0]
      handlers.loadFile file
      .then ->
        handlers.currentPath null
