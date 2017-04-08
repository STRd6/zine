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

{title} = require "./pixie"
[..., version] = title.split('-')

VersionTemplate = require "./templates/version"
document.body.appendChild VersionTemplate
  version: version

# Desktop
Explorer = require "./apps/explorer"
document.body.appendChild Explorer()

system.writeFile "feedback.exe", new Blob [""], type: "application/exe"
system.writeFile "issue-1/zine1.exe", new Blob [""], type: "application/exe"
system.writeFile "issue-2/zine2.exe", new Blob [""], type: "application/exe"
system.writeFile "issue-3/zine3.exe", new Blob [""], type: "application/exe"
system.writeFile "issue-4/zine4.exe", new Blob [""], type: "application/exe"
system.writeFile "My Briefcase", new Blob [""], type: "application/briefcase"

require("./issues/2017-04")()

system.autoboot()
# system.dumpModules()
