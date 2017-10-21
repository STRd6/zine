AppDrop = require "../lib/app-drop"

module.exports = (I, self) ->
  appData = null

  self.extend
    # The final step in launching an application in the OS
    # This wires up event streams, drop events, adds the app to the list
    # of running applications, and attaches the app's element to the DOM
    attachApplication: (app, options={}) ->
      # Bind Drop events
      AppDrop(app)

      # TODO: Bind to app event streams

      # TODO: Add to list of apps

      document.body.appendChild app.element

    launchAppByAppData: (datum, path) ->
      {name, icon, width, height, src} = datum

      app = self.iframeApp
        title: name
        emojiIcon: icon
        width: width
        height: height
        src: src

      if path
        self.readFile path
        .then (blob) ->
          app.loadFile(blob, path)

      self.attachApplication app

    launchAppByName: (name, path) ->
      [datum] = appData.filter (datum) ->
        datum.name is name

      if datum
        self.launchAppByAppData(datum, path)

    initAppSettings: ->
      self.readFile("System/apps.json")
      .then (blob) ->
        if blob
          blob.readAsJSON()
        else
          []
      .then (data) ->
        appData = data

        data.forEach (datum) ->
          self.installAppHandler(datum)

          if datum.launchAtStartup
            launchAppByAppData(datum)

    removeApp: (name, noPersist) ->
      appData = (appData or []).filter (datum) ->
        if datum.name != name
          true
        else
          # Remove handler
          self.removeHandler(datum.handler)
          return false

      self.writeFile "System/apps.json", JSON.toBlob(appData) unless noPersist

    installApp: (appData) ->
      console.log "install", appData
      # Only one app per name
      self.removeApp(appData.name, true)

      appData = appData.concat [appData]

      self.installAppHandler(appData)

      self.writeFile "System/apps.json", JSON.toBlob(appData)

    installAppHandler: (datum) ->
      {name, associations} = datum

      associations = [].concat(associations or [])

      datum.handler =
        name: name
        filter: ({path}) ->
          associations.some (association) ->
            endsWith path, association
        fn: (file) ->
          self.launchAppByName name, file?.path

      self.registerHandler datum.handler
