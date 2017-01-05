require "./extensions"

System = require "./system"
global.system = System()

{Style} = system.UI
style = document.createElement "style"
style.innerHTML = Style.all + "\n" + require("./style")
document.head.appendChild style

require("./issues/2017-01")()
