require("analytics").init("UA-3464282-16")

require "./extensions"

require "./lib/outbound-clicks"
require "./lib/error-reporter"

global.Hamlet = require "./lib/hamlet"

System = require "./system"
global.system = System()
system.PACKAGE = PACKAGE # For debugging

{Style} = system.UI
style = document.createElement "style"
style.innerHTML = Style.all + "\n" + require("./style")
document.head.appendChild style

# Desktop
Explorer = require "./apps/explorer"
document.body.appendChild Explorer()

VersionTemplate = require "./templates/version"
document.body.appendChild VersionTemplate
  version: system.version

SiteURLTemplate = require "./templates/site-url"
document.body.appendChild SiteURLTemplate()

HomeButton = require "./presenters/home-button"
document.body.appendChild HomeButton()

system.writeFile "feedback.exe", new Blob [""], type: "application/exe"
system.writeFile "issue-1/zine1.exe", new Blob [""], type: "application/exe"
system.writeFile "issue-2/zine2.exe", new Blob [""], type: "application/exe"
system.writeFile "issue-3/zine3.exe", new Blob [""], type: "application/exe"
system.writeFile "issue-4/zine4.exe", new Blob [""], type: "application/exe"
system.writeFile "My Briefcase", new Blob [""], type: "application/briefcase"

system.autoboot()
# system.dumpModules()

require("./issues/2017-05")()
