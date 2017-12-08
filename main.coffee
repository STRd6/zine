require("analytics").init("UA-3464282-16")

require "./extensions"

require "./lib/outbound-clicks"
require "./lib/error-reporter"

# global.Hamlet = require "./lib/hamlet"
global.Jadelet = require "./lib/jadelet.min"

System = require "./system"
global.system = System()
system.PACKAGE = PACKAGE # For debugging

{Style} = system.UI
style = document.createElement "style"
style.innerHTML = Style.all + "\n" + require("./style")
document.head.appendChild style

# Drag shenanigans
document.addEventListener "dragstart", ->
  document.body.classList.add "drag-active"
endDrag = ->
  document.body.classList.remove "drag-active"
document.addEventListener "mouseup", endDrag
document.addEventListener "dragend", endDrag

# Desktop
Explorer = require "./apps/explorer"
document.body.appendChild Explorer()

VersionTemplate = require "./templates/version"
document.body.appendChild VersionTemplate
  version: system.version

SiteURLTemplate = require "./templates/site-url"
document.body.appendChild SiteURLTemplate()

HomeButton = require "./presenters/home-button"
document.body.appendChild HomeButton(system)

system.writeFile "feedback.exe", new Blob [""], type: "application/exe"
system.writeFile "My Briefcase", new Blob [""], type: "application/briefcase"

system.autoboot()
# system.dumpModules()
system.initAppSettings()

->
  system.removeApp("Test")

-> # For testing
  system.installApp
    name: "Test"
    src: "https://fs.whimsy.space/us-east-1:90fe8dfb-e9d2-45c7-a347-cf840a3e757f/public/test2/index.html"
    launchAtStartup: true
    width: 100
    height: 100
    icon: "T"
    associations:
      type: []
      extension: ["test"]

# require("./issues/2017-10")()
