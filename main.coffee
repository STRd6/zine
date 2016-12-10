{ContextMenu, MenuBar, Modal, Progress, Style, Window} = require "ui"

style = document.createElement "style"
style.innerHTML = Style.all
document.head.appendChild style

windowView = Window
  yolo: {}
document.body.appendChild windowView.element
