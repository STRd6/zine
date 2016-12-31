require "./extensions"

OS = require "../os"
global.system = os = OS()

{Style} = os.UI
style = document.createElement "style"
style.innerHTML = Style.all + "\n" + require("./style")
document.head.appendChild style

require("./issues/2017-01")(os)
