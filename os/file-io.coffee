# Handle basic file saving/loading/picking, displaying modals/ui.

# Host must provide the following methods
#   `loadFile` Take a blob and load it as the application state.
#   `saveData` Return a promise that will be fulfilled with a blob of the
#     current application state.
#   `newFile` Initialize the application to an empty state.

module.exports = (I, self) ->
  {Modal} = system.UI

  currentPath = ""
  # TODO: Update saved to be false when model changes
  saved = true

  self.extend
    new: ->
      if saved
        currentPath = ""
        self.newFile()
      else
        Modal.confirm "You will lose unsaved progress, continue?"
        .then (result) ->
          if result
            saved = true
            self.newFile()

    open: ->
      # TODO: Prompt if unsaved
      # TODO: File browser
      Modal.prompt "File Path", currentPath
      .then system.readFile
      .then self.loadFile

    save: ->
      if currentPath
        self.saveData()
        .then (blob) ->
          system.writeFile currentPath, blob
      else
        self.saveAs()

    saveAs: ->
      Modal.prompt "File Path", currentPath
      .then (path) ->
        if path
          currentPath = path
          self.save()

  return self
