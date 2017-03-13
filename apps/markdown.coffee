# Render Markdown

FileIO = require "../os/file-io"
Model = require "model"

{absolutizePath} = require "../util"

isRelative = (url) ->
  url.match /^\.\.?\//

module.exports = ->
  # Global system
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI

  container = document.createElement 'container'
  container.style.padding = "1rem"

  baseDir = ""
  navigationStack = []
  # TODO: Maintain a container stack to keep state

  navigateToPath = (path) ->
    system.readFile(path)
    .then (blob) ->
      handlers.loadFile(blob, path)

  rewriteURL = (url) ->
    Promise.resolve()
    .then ->
      if isRelative(url)
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
      navigationStack.push path
      baseDir = path.replace /\/[^/]*$/, ""

      blob.readAsText()
      .then (textContent) ->
        if path.match /\.html$/
          container.innerHTML = textContent
        else
          container.innerHTML = marked(textContent)

        rewriteURLs(container)

    saveData: ->

    exit: ->
      windowView.element.remove()

  # Handle Links
  container.addEventListener "click", (e) ->
    [anchor] = e.path.filter (element) ->
      element.nodeName is "A"

    if anchor
      url = anchor.getAttribute("href")

      if isRelative(url)
        e.preventDefault()
        path = absolutizePath baseDir, url

        # Navigate to page
        navigateToPath(path)


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

  windowView.element.setAttribute("tabindex", -1)
  windowView.element.addEventListener "keydown", (e) ->
    {key} = e

    if key is "Backspace"
      e.preventDefault()
      if navigationStack.length > 1
        navigationStack.pop()

        lastPath = navigationStack.pop()
        navigateToPath(lastPath)

  windowView.loadFile = handlers.loadFile

  return windowView
