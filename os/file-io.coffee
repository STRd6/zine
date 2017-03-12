# Handle basic file saving/loading/picking, displaying modals/ui.

# Host must provide the following methods
#   `loadFile` Take a blob and load it as the application state.
#   `saveData` Return a promise that will be fulfilled with a blob of the
#     current application state.
#   `newFile` Initialize the application to an empty state.

module.exports = (I, self) ->
  {Observable} = system
  {Modal} = system.UI

  currentPath = Observable ""
  saved = Observable true

  confirmUnsaved = ->
    return Promise.resolve() if saved()

    new Promise (resolve, reject) ->
      Modal.confirm "You will lose unsaved progress, continue?"
      .then (result) ->
        if result
          resolve()
        else
          reject()

  self.extend
    currentPath: currentPath
    saved: saved
    new: ->
      if saved()
        currentPath ""
        self.newFile()
      else
        confirmUnsaved()
        .then ->
          saved true
          self.newFile()

    open: ->
      confirmUnsaved()
      .then  ->
        # TODO: File browser
        Modal.prompt "File Path", currentPath()
        .then (newPath) ->
          if newPath
            currentPath newPath
          else
            throw new Error "No path given"
        .then (path) ->
          system.readFile path, true
        .then (file) ->
          self.loadFile file

    save: ->
      if currentPath()
        self.saveData()
        .then (blob) ->
          system.writeFile currentPath(), blob, true
        .then ->
          saved true
          currentPath()
      else
        self.saveAs()

    saveAs: ->
      Modal.prompt "File Path", currentPath()
      .then (path) ->
        if path
          currentPath path
          self.save()

  return self
