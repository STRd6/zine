# View and Manipulate Images
# TODO: Kick out of core

FileIO = require "../os/file-io"
Model = require "model"

module.exports = ->
  # Global system
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI

  # system.Achievement.unlock "Look at that"

  video = document.createElement 'video'
  video.loop = true
  video.autoplay = true

  handlers = Model().include(FileIO).extend
    loadFile: (blob) ->
      video.src = URL.createObjectURL(blob)

    saveData: ->

    exit: ->
      windowView.element.remove()

  windowView = Window
    title: "Videomaster"
    iconEmoji: "📹"
    content: video
    width: 640
    height: 480

  windowView.send = (method, args...) ->
    handlers[method](args...)

  return windowView
