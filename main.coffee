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

# Launch Current Issue
require("./issues/2017-02")()
