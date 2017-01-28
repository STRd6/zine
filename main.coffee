require("analytics").init("UA-3464282-16")

require "./extensions"

global.Hamlet = require "./lib/hamlet"

System = require "./system"
global.system = System()

{Style} = system.UI
style = document.createElement "style"
style.innerHTML = Style.all + "\n" + require("./style")
document.head.appendChild style

require("./issues/2017-01")()
