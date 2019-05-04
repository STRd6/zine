MyBriefcase = require "../apps/my-briefcase"

Explorer = require "../apps/explorer"
PkgFS = require "../lib/pkg-fs"
AppDrop = require "../lib/app-drop"
IFrameApp = require "../lib/iframe-app"
{
  baseDirectory
  endsWith
  execute
  htmlForPackage
} = require "../util"

{Modal, Observable} = require "ui"

lastAppId = 1024

module.exports = (I, self) ->
  # Handlers use type and contents path info to do the right thing
  # The first handler that matches is the default handler, the rest are available
  # from context menu
  handlers = [{
    name: "Run"
    filter: (file) ->
      file.type is "application/javascript" or
      file.path.match(/\.js$/) or
      file.path.match(/\.coffee$/) or
      file.path.match(/\.exe$/)
    fn: (file) ->
      self.launchAppByPath file.path
  }, {
    name: "Run"
    filter: (file) ->
      file.path.match(/💾$/) or
      file.path.match(/\.json$/)
    fn: ({path}) ->
      self.readFile(path)
      .then (blob) ->
        blob.readAsJSON()
      .then (pkg) ->
        self.executePackageInIFrame pkg, baseDirectory(path)
  }, {
    name: "Create Package"
    filter: (file) ->
      file.type is "application/javascript" or
      file.path.match(/\.js$/) or
      file.path.match(/\.coffee$/) or
      file.path.match(/pixie\.cson$/)
    fn: ({path}) ->
      self.packageProgram(path)
      .then (pkg) ->
        Modal.prompt "Filename", "#{path}/../master💾"
        .then (path) ->
          self.writeFile(path, JSON.toBlob(pkg, "application/json"))
  }, {
    name: "Explore Package"
    filter: (file) ->
      file.path.match(/💾$/) or
      file.path.match(/\.json$/)
    fn: (file) ->
      system.readFile(file.path)
      .then (blob) ->
        blob.readAsJSON()
      .then (pkg) ->
        mountPath = file.path + "/"
        fs = PkgFS(pkg, file.path)
        system.fs.mount mountPath, fs

        # TODO: Can we make the explorer less specialized here?
        element = Explorer
          path: mountPath

        windowView = system.UI.Window
          title: mountPath
          content: element
          menuBar: null
          width: 640
          height: 480
          iconEmoji: "📂"

        document.body.appendChild windowView.element
  }, {
    name: "PDF Viewer"
    filter: (file) ->
      file.path.match /\.pdf$/
    fn: (file) ->
      file.blob.getURL()
      .then (url) ->
        self.launchAppByAppData
          src: url
          sandbox: false # Need Chrome's pdf plugin to view pdfs
          title: file.path
  }, {
    name: "My Briefcase"
    filter: ({path}) ->
      path.match /My Briefcase$/
    fn: ->
      system.openBriefcase()
  }]

  handle = (file) ->
    handler = handlers.find ({filter}) ->
      filter(file)

    if handler
      handler.fn(file)
    else
      throw new Error "No handler for files of type #{file.type}"

  specialApps =
    "Audio Bro": require "../apps/audio-bro"
    "Image Viewer": require "../apps/filter"
    "Videomaster": require "../apps/video"

  self.extend
    appData: Observable []
    runningApplications: Observable []

    saved: ->
      self.runningApplications().every (app) ->
        !app.saved? or app.saved()

    # Open a file
    open: (file) ->
      handle(file)

    # Return a list of all handlers that can be used for this file
    openersFor: (file) ->
      handlers.filter (handler) ->
        handler.filter(file)

    # Add a handler to the list of handlers, position zero is highest priority
    # Default is lowest priority
    registerHandler: (handler, position=0) ->
      handlers.splice(position, 0, handler)

    removeHandler: (handler) ->
      position = handlers.indexOf(handler)
      if position >= 0
        handlers.splice(position, 1)
        return handler

      return

    handlers: ->
      handlers.slice()

    openBriefcase: ->
      app = MyBriefcase()
      system.attachApplication app

    openPath: (path) ->
      self.readFile path
      .then self.open

    launchAppByPath: (path, inputPath) ->
      if path.match(/\.exe$/)
        self.readFile(path)
        .then (blob) ->
          blob.readAsJSON()
        .then (data) ->
          self.launchAppByAppData data,
            inputPath: inputPath
            env:
              pwd: baseDirectory path
      else if path.match(/\.js$|\.coffee$/)
        self.executeInIFrame path, inputPath
      else
        Promise.reject new Error "Could not launch #{path}"

    # Build a package for the file at `absolutePath`. Execute that package in an
    # isolated context from the core system. It can communicate with the system
    # over `postMessage`.
    # It happens to be in an iframe but no reason it couldn't be web worker or
    # something else.
    executeInIFrame: (absolutePath, inputPath) ->
      self.packageProgram(absolutePath)
      .then (pkg) ->
        self.executePackageInIFrame pkg, baseDirectory(absolutePath), inputPath

    # Execute a package in the context of an iframe
    # The package is converted into a blob url containing an html source that
    # will execute the package.
    executePackageInIFrame: (pkg, pwd="/", inputPath) ->
      data = self.dataForPackage(pkg)

      self.launchAppByAppData data,
        env:
          pwd: pwd
        inputPath: inputPath

    # Create an appData for a package, it includes the src and config.
    dataForPackage: (pkg) ->
      html = self.htmlForPackage pkg
      blob = new Blob [html],
        type: "text/html; charset=utf-8"

      src = URL.createObjectURL blob

      return Object.assign {}, pkg.config, {src: src}

    htmlForPackage: htmlForPackage

    # The final step in launching an application in the OS
    # This wires up event streams, drop events, adds the app to the list
    # of running applications, and attaches the app's element to the DOM
    attachApplication: (app, options={}) ->
      app._id = lastAppId
      lastAppId += 1

      # Bind Drop events
      AppDrop(app)

      # TODO: Bind to app event streams

      # Add to list of apps
      self.runningApplications.push app

      # If apps don't implement an exit make sure to give them a default one.
      app.exit ?= ->
        app.element.remove()
        app.trigger "exit"

      # JSONify apps so their handles can be passed across postMessage
      app[system.embalmSymbol()] ?= ->
        type: "Application"
        id: app._id
        title: app.title()

      # Override the default close behavior to trigger exit events
      app.close = app.exit

      app.on "exit", ->
        self.runningApplications.remove app
        self.trigger "application", "stop", appData

      document.body.appendChild app.element

      appData =
        id: app._id

      self.trigger "application", "start", appData

      return appData

    ###
    Apps can come in many types based on what attributes are present.
      script: script that executes inline
      src: iframe apps
      name: a named system application
    ###
    launchAppByAppData: (datum, options={}) ->
      {name, icon, width, height, src, sandbox, script, title, allow} = datum
      {inputPath, env} = options

      if script
        execute script, {},
          system: system
        return

      if specialApps[name]
        app = specialApps[name]()
      else
        app = IFrameApp
          allow: allow
          env: env
          title: name or title
          icon: icon
          width: width
          height: height
          sandbox: sandbox
          src: src

      if inputPath
        self.readFile inputPath
        .then (blob) ->
          app.send "application", "loadFile", blob, inputPath

      self.attachApplication app

    # Look up the app data for the given app name and launch that app
    # we also download and cache remote apps here
    launchAppByName: (name, path) ->
      [datum] = self.appData.filter (datum) ->
        datum.name is name

      if datum
        {packageURL} = datum
        if packageURL
          self.cachedOrFetchAppPackage(packageURL, name)
          .then (pkg) ->
            self.executePackageInIFrame(pkg, baseDirectory(path), path)
        else
          self.launchAppByAppData datum,
            env:
              pwd: baseDirectory path
            inputPath: path
      else
        throw new Error "No app found named '#{name}'"

    cachedOrFetchAppPackage: (packageURL, cachedName) ->
      cachedPath = "/System/Apps/#{cachedName}💾"

      self.readFile(cachedPath)
      .then (blob) ->
        blob.readAsJSON()
      .catch (e) ->
        if e.message.match /File not found/i
          fetch(packageURL).then (result) ->
            result.json()
          .then (pkg) ->
            self.writeFile cachedPath, JSON.toBlob(pkg)

            return pkg

    tell: (appId, method, params...) ->
      self.appById(appId).send("application", method, params...)

    kill: (appId) ->
      self.appById(appId).exit()

    appById: (id) ->
      [app] = self.runningApplications().filter (app) ->
        app._id is id

      throw new Error "No app with id #{id}" unless app

      return app

    initAppSettings: ->
      systemApps.forEach self.installAppHandler
      # TODO: Install user apps
      # could be a local index like this remote one

      # Fetch whimsy.space app index
      fetch("https://whimsy.space/apps/index.json").then (result) ->
        result.json()
      .then (appData) ->
        appData.forEach self.installAppHandler

        self.appData self.appData.concat appData

      self.appData systemApps

    removeApp: (name) ->
      self.appData self.appData.filter (datum) ->
        if datum.name is name
          # Remove handler
          console.log "removing handler", datum
          self.removeHandler(datum.handler)
          return false
        else
          true

    installApp: (datum) ->
      # Only one app per name
      self.removeApp(datum.name, true)

      self.appData self.appData.concat [datum]

      self.installAppHandler(datum)

    installAppHandler: (datum) ->
      {name, associations} = datum

      associations = [].concat(associations or [])

      datum.handler =
        name: name
        filter: ({type, path}) ->
          associations.some (association) ->
            matchAssociation(association, type, path)
        fn: (file) ->
          self.launchAppByName name, file?.path

      self.registerHandler datum.handler

  systemApps = [{
    name: "Chateau"
    icon: "🍷"
    src: "https://danielx.net/chateau/"
    sandbox: false
    width: 960
    height: 540
  }, {
    name: "Pixie Paint"
    icon: "🖌️"
    src: "https://danielx.net/pixel-editor/"
    associations: ["mime:^image/"]
    width: 640
    height: 480
    achievement: "Pixel perfect"
  }, {
    name: "Code Editor"
    icon: "☢️"
    src: "https://danielx.whimsy.space/danielx.net/code/"
    associations: [
      "mime:^application/javascript"
      "mime:^text"
      "mime:json$"
      "💾"
      "coffee"
      "cson"
      "html"
      "jadelet"
      "js"
      "json"
      "md"
      "styl"
      "css"
    ]
    achievement: "Notepad.exe"
  }, {
    name: "Monaco Editor"
    icon: "☢️"
    src: "https://danielx.whimsy.space/danielx.net/code/monaco/"
    associations: [
      "mime:^application/javascript"
      "mime:^text"
      "mime:json$"
      "💾"
      "html"
      "jadelet"
      "js"
      "json"
      "md"
      "styl"
      "css"
    ]
    achievement: "Notepad.exe"
  }, {
    name: "Sound Recorder"
    icon: "🎙️"
    src: "https://danielx.whimsy.space/danielx.net/sound-recorder/"
    allow: "microphone"
    sandbox: false
  }, {
    name: "Audio Bro"
    icon: "🎶"
    associations: ["mime:^audio/"]
  }, {
    name: "Image Viewer"
    icon: "👓"
    associations: ["mime:^image/"]
  }, {
    name: "Videomaster"
    icon: "📹"
    associations: ["mime:^video/"]
  }, {
    name: "Dr Wiki"
    icon: "📖"
    associations: ["md", "html"]
    src: "https://danielx.whimsy.space/danielx.net/dr-wiki/"
  }, {
    name: "FXZ Edit"
    icon: "📈"
    associations: ["fxx", "fxz"]
    src: "https://danielx.whimsy.space/danielx.net/fxz-edit/"
  }, {
    name: "First"
    icon: " 1️⃣"
    script: "system.launchIssue('2016-12')"
    category: "Issues"
  }, {
    name: "Enter the Dungeon"
    icon: "🏰"
    script: "system.launchIssue('2017-02')"
    category: "Issues"
  }, {
    name: "ATTN: K-Mart Shoppers"
    icon: "🏬"
    script: "system.launchIssue('2017-03')"
    category: "Issues"
  }, {
    name: "Disco Tech"
    icon: "💃"
    script: "system.launchIssue('2017-04')"
    category: "Issues"
  }, {
    name: "A May Zine"
    icon: "🌻"
    script: "system.launchIssue('2017-05')"
    category: "Issues"
  }, {
    name: "Summertime Radness"
    icon: "🐝"
    script: "system.launchIssue('2017-06')"
    category: "Issues"
  }, {
    name: "Spoopin Right Now"
    icon: "🎃"
    script: "system.launchIssue('2017-10')"
    category: "Issues"
  }, {
    name: "Do you dab"
    icon: "💃"
    script: "system.launchIssue('2017-11')"
    category: "Issues"
  }, {
    name: "A Very Paranormal X-Mas"
    icon: "👽"
    script: "system.launchIssue('2017-12')"
    category: "Issues"
  }, {
    name: "Bionic Hotdog"
    category: "Games"
    src: "https://danielx.net/grappl3r/"
    width: 960
    height: 540
    icon: "🌭"
  }, {
    name: "Dungeon of Sadness"
    icon: "😭"
    category: "Games"
    src: "https://danielx.net/ld33/"
    width: 648
    height: 507
    achievement: "The dungeon is in our heart"
  }, {
    name: "Contrasaurus"
    icon: "🍖"
    category: "Games"
    src: "https://contrasaur.us/"
    width: 960
    height: 540
    achievement: "Rawr"
    sandbox: false
  }, {
    name: "Dangerous"
    icon: "🐱"
    category: "Games"
    src: "https://projects.pixieengine.com/106/"
  }, {
    name: "Quest for Meaning"
    icon: "❔"
    category: "Games"
    src: "https://danielx.whimsy.space/apps/qfm/"
    width: 648
    height: 510
  }, {
    name: "Space Dolphin IV"
    icon: "🐬"
    category: "Games"
    src: "https://projects.pixieengine.com/1439/"
    width: 960 + 8
    height: 640 + 27
    achievement: "In space, nobody can hear you in space"
  }].reverse()

  return self

matchAssociation = (association, type, path) ->
  if association.indexOf("mime:") is 0
    regex = new RegExp association.substr(5)

    type.match(regex)
  else
    endsWith path, association
