require("analytics").init("UA-3464282-16")

require "./extensions"

require "./lib/outbound-clicks"
require "./lib/error-reporter"

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

system.writeFile "feedback.exe", new Blob [
  JSON.stringify
    achievement: "We value your input"
    title: "Whimsy Space Feedback"
    src: "https://docs.google.com/forms/d/e/1FAIpQLSfAK8ZYmMd4-XsDqyTK4soYGWApGD9R33nReuqwG-TxjXaGFg/viewform?embedded=true"
    width: 600
    height: 600
    sandbox: false
], type: "application/exe"
system.writeFile "My Briefcase", new Blob [""], type: "application/briefcase"

system.autoboot()
system.initAppSettings()

require("./issues/2018-01")()
