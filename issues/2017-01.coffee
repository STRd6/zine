Model = require "model"
Chateau = require "../apps/chateau"
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
      a(href="#vista")
        img(src="https://s-media-cache-ak0.pinimg.com/originals/a3/ba/56/a3ba56cef667d14b54023cd624d4e070.jpg")
    """
    vista: """
      a(href="#table")
        img(src="https://books.google.com/books/content?id=2cgDAAAAMBAJ&rview=1&pg=PA10&img=1&zoom=3&hl=en&sig=ACfU3U3477L46r0KxSQusJrQ6w9qxIQ70w&w=1280")
    """
    table: """
      div
        h1 Table of Contents
        ul
          li
            a(href="#front") Cover
          li
            a(href="#vista") Excerpt from Windows Vista Magazine
          li
            a(href="#table") Table of Contents
          li
            a(href="#random") Random Thoughts
    """
    random: """
      div
        h1 Random Thoughts
        p Don't you hate it when you're cooking something and you look at the stove clock and think it's 3:75 and you're late for your appointment but it was just the temperature and also 3:75 isn't even a real time?
        p I suggest you bone up a bit on torts before the next attempt at the bar exam.
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
    chateau: ->
      app = Chateau(system)
      document.body.appendChild app.element

  menuBar = MenuBar
    items: parseMenu """
      [H]ello
        [W]ait Around For A Bit
      [A]pps
        [C]hateau
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
