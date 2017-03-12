# Render Markdown

FileIO = require "../os/file-io"
Model = require "model"

{absolutizePath} = require "../util"

module.exports = ->
  # Global system
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI

  container = document.createElement 'container'
  container.style.padding = "1rem"

  baseDir = ""

  rewriteURL = (url) ->
    Promise.resolve()
    .then ->
      if url.match /^\.\.?\// # Relative paths
        targetPath = absolutizePath baseDir, url

        system.urlForPath(targetPath)
      else if url.match /^\// # Absolute paths
        targetPath = absolutizePath "", url
        system.urlForPath(targetPath)
      else
        url

  rewriteURLs = (container) ->
    container.querySelectorAll("img").forEach (img) ->
      url = img.getAttribute("src")

      if url
        rewriteURL(url)
        .then (url) ->
          img.src = url

  handlers = Model().include(FileIO).extend
    loadFile: (blob, path) ->
      baseDir = path.replace /\/[^/]*$/, ""

      blob.readAsText()
      .then (textContent) ->
        container.innerHTML = marked(textContent)

        rewriteURLs(container)

    saveData: ->

    exit: ->
      windowView.element.remove()

  menuBar = MenuBar
    items: parseMenu """
      [F]ile
        [O]pen
        -
        E[x]it
    """
    handlers: handlers

  windowView = Window
    title: "Markdown"
    content: container
    menuBar: menuBar.element
    width: 720
    height: 480

  windowView.loadFile = handlers.loadFile

  return windowView
