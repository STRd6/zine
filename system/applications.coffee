MyBriefcase = require "../apps/my-briefcase"

AppDrop = require "../lib/app-drop"
IFrameApp = require "../lib/iframe-app"
{endsWith, execute} = require "../util"

{Observable} = require "ui"

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
      self.pathAsApp file.path
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

    # Open a file
    open: (file) ->
      handle(file)

    # Return a list of all handlers that can be used for this file
    openersFor: (file) ->
      handlers.filter (handler) ->
        handler.filter(file)

    # Add a handler to the list of handlers, position zero is highest priority
    # Default is lowest priority
    registerHandler: (handler, position) ->
      position ?= handlers.length
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

    pathAsApp: (path) ->
      if path.match(/\.exe$/)
        self.readFile(path)
        .then (blob) ->
          blob.readAsJSON()
        .then self.launchAppByAppData
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

      # Add to list of apps
      self.runningApplications.push app

      # Override the default close behavior to trigger exit events
      if app.exit?
        app.close = app.exit

      app.on "exit", ->
        self.runningApplications.remove app

      document.body.appendChild app.element

    ###
    Apps can come in many types based on what attributes are present.
      script: script that executes inline
      src: iframe apps
      name: a named system application
    ###
    launchAppByAppData: (datum, path) ->
      {name, icon, width, height, src, sandbox, script, title, allow} = datum

      if script
        execute script, {},
          system: system
        return

      if specialApps[name]
        app = specialApps[name]()
      else
        app = IFrameApp
          allow: allow
          title: name or title
          icon: icon
          width: width
          height: height
          sandbox: sandbox
          src: src

      if path
        self.readFile path
        .then (blob) ->
          app.send "loadFile", blob, path

      self.attachApplication app

    launchAppByName: (name, path) ->
      [datum] = self.appData.filter (datum) ->
        datum.name is name

      if datum
        self.launchAppByAppData(datum, path)
      else
        throw new Error "No app found named '#{name}'"

    initAppSettings: ->
      systemApps.forEach self.installAppHandler
      # TODO: Install user apps

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

    persistApps: ->
      self.writeFile "System/apps.json", JSON.toBlob(systemApps)

    installAppHandler: (datum) ->
      {name, associations, script} = datum

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
      "mime:json$"
      "coffee"
      "cson"
      "html"
      "jadelet"
      "js"
      "json"
      "md"
      "styl"
      "exe"
    ]
    achievement: "Notepad.exe"
  }, {
    name: "Notepad"
    icon: "📝"
    src: "https://danielx.whimsy.space/danielx.net/notepad/"
    associations: ["mime:^text/", "mime:^application/javascript"]
    achievement: "Notepad.exe"
  }, {
    name: "Progenitor"
    icon: "🌿"
    src: "https://danielx.whimsy.space/danielx.net/editor/zine2/"
    associations: [
      "mime:^application/zineos-package"
    ]
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
  }]

  return self

matchAssociation = (association, type, path) ->
  if association.indexOf("mime:") is 0
    regex = new RegExp association.substr(5)

    type.match(regex)
  else
    endsWith path, association
