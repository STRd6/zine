Model = require "model"

module.exports = ->
  {ContextMenu, MenuBar, Modal, Observable, Progress, Table, Util:{parseMenu}, Window} = system.UI

  frame = document.createElement "iframe"
  frame.src = "https://danielx.net/ld33/"

  system.Achievement.unlock "The dungeon is in our heart"

  windowView = Window
    title: "Dungeon of Sadness"
    content: frame
    menuBar: null
    width: 648
    height: 507

  return windowView
