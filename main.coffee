{ContextMenu, MenuBar, Modal, Progress, Style, Window} = require "ui"

style = document.createElement "style"
style.innerHTML = Style.all
document.head.appendChild style

windowView = Window
  title: "ZineOS Volume 1 | Issue 1 | December 2016"
document.body.appendChild windowView.element
