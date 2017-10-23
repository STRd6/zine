AppDrop = require "../lib/app-drop"
{endsWith} = require "../util"

module.exports = (I, self) ->
  appData = null

  self.extend
    iframeApp: require "../lib/iframe-app"

    openPath: (path) ->
      self.readFile path
      .then self.open

    pathAsApp: (path) ->
      if path.match(/\.exe$/)
        self.readFile path
        .then (blob) ->
          blob.readAsJSON()
        .then (data) ->
          self.iframeApp data
      else if path.match(/🔗$|\.link$/)
        self.readFile path
        .then (blob) ->
          blob.readAsText()
        .then self.evalCSON
        .then (data) ->
          self.iframeApp data
      else if path.match(/\.js$|\.coffee$/)
        self.executeInIFrame(path)
      else
        Promise.reject new Error "Could not launch #{path}"

    execPathWithFile: (path, file) ->
      self.pathAsApp(path)
      .then (app) ->
        if file
          {path} = file
          self.readFile path
          .then (blob) ->
            app.send "loadFile", blob, path

        self.attachApplication(app)

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
          app.send "loadFile", blob, path

      self.attachApplication app

    launchAppByName: (name, path) ->
      debugger
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

        self.installDefaultApplications()

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

    installApp: (datum) ->
      console.log "install", datum
      # Only one app per name
      self.removeApp(datum.name, true)

      appData = appData.concat [datum]

      self.installAppHandler(datum)

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

    installDefaultApplications: ->
      [{
        name: "Dr Wiki"
        associations: ["md", "html"]
        src: "https://danielx.whimsy.space/danielx.net/dr-wiki/"
      }, {
        name: "Bionic Hotdog"
        category: "Games"
        src: "https://danielx.net/grappl3r/"
        width: 960
        height: 540
        icon: "🌭"
      }, {
        name: "Chateau"
        src: "https://danielx.net/chateau/"
        width: 960
        height: 540
        icon: "🍷"
      }].forEach self.installApp

  return self
