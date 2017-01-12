Model = require "model"
PixiePaint = require "../apps/pixel"
Spreadsheet = require "../apps/spreadsheet"
TextEditor = require "../apps/text-editor"

Social = require "../social/social"

Explorer = require "../apps/explorer"

{parentElementOfType, emptyElement} = require "../util"

module.exports = ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI

  document.body.appendChild Explorer()

  container = document.createElement "container"

  pages =
    front: """
      a(href="#enter")
        img(src="https://s-media-cache-ak0.pinimg.com/originals/a3/ba/56/a3ba56cef667d14b54023cd624d4e070.jpg")
    """
    enter: """
      a(href="#yolo")
        img(src="https://books.google.com/books/content?id=2cgDAAAAMBAJ&rview=1&pg=PA10&img=1&zoom=3&hl=en&sig=ACfU3U3477L46r0KxSQusJrQ6w9qxIQ70w&w=1280")
    """

  Object.keys(pages).forEach (pageName) ->
    value = pages[pageName]
    pages[pageName] = system.compileTemplate(value)({})

  container.appendChild pages.front

  handlers = Model().include(Social).extend
    area: ->
      "2017-01"
    mSAccess97: ->
      app = Spreadsheet(system)
      document.body.appendChild app.element
    textEditor: ->
      app = TextEditor(system)
      document.body.appendChild app.element
    pixiePaint: ->
      app = PixiePaint(system)
      document.body.appendChild app.element

  menuBar = MenuBar
    items: parseMenu """
      [H]ello
        [W]ait Around For A Bit
      [A]pps
        [M]S Access 97
        [T]ext Editor
        [P]ixie Paint
      #{Social.menuText}
    """
    handlers: handlers

  windowView = Window
    title: "ZineOS Volume 1 | Issue 2 | ENTER THE DUNGEON | January 2017"
    content: container
    menuBar: menuBar.element
    width: 1228
    height: 936
    x: 0
    y: 0
  
  windowView.element.addEventListener "click", (e) ->
    anchor = parentElementOfType("a", e.target)

    if anchor
      next = anchor.getAttribute('href')

      if next.match /^\#/
        e.preventDefault()
        emptyElement(container)
        page = next.substr(1)
        container.appendChild(pages[page])

  document.body.appendChild windowView.element
