require("analytics").init("UA-3464282-16")

require "./extensions"

require "./lib/outbound-clicks"
require "./lib/error-reporter"

global.Hamlet = require "./lib/hamlet"

System = require "./system"
global.system = System()

{Style} = system.UI
style = document.createElement "style"
style.innerHTML = Style.all + "\n" + require("./style")
document.head.appendChild style

# Desktop
Explorer = require "./apps/explorer"
document.body.appendChild Explorer()

system.writeFile "feedback.exe", new Blob [""], type: "application/exe"
system.writeFile "issue-1/zine1.exe", new Blob [""], type: "application/exe"
system.writeFile "issue-2/zine2.exe", new Blob [""], type: "application/exe"
system.writeFile "issue-3/zine3.exe", new Blob [""], type: "application/exe"

require("./issues/2017-03")()

system.autoboot()
# system.dumpModules()
