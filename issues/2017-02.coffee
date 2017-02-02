Achievement = require "../lib/achievement"
Model = require "model"
Chateau = require "../apps/chateau"
PixiePaint = require "../apps/pixel"
Spreadsheet = require "../apps/spreadsheet"
TextEditor = require "../apps/text-editor"

Social = require "../social/social"

{parentElementOfType, emptyElement} = require "../util"

module.exports = ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI

  container = document.createElement "container"

  setTimeout ->
    system.Achievement.unlock "Issue 2"
  #, 3000

  system.writeFile "issue-2/around.md", new Blob [require "../stories/around-the-world"], type: "text/markdown"
  system.writeFile "issue-2/provision.txt", new Blob [require "../stories/provision"], type: "text/plain"
  system.writeFile "issue-2/dungeon-dog.txt", new Blob [require "../stories/dungeon-dog"], type: "text/plain"
  system.writeFile "issue-2/dsad.exe", new Blob [""], type: "application/exe"
  system.writeFile "issue-2/zine2.exe", new Blob [""], type: "application/exe"

  system.writeFile "issue-1/zine1.exe", new Blob [""], type: "application/exe"

  pages =
    front: """
      a(href="#vista")
        img(src="https://s-media-cache-ak0.pinimg.com/originals/a3/ba/56/a3ba56cef667d14b54023cd624d4e070.jpg")
    """
    vista: """
      a(href="#table")
        img(width=640 height="auto" src="https://books.google.com/books/content?id=2cgDAAAAMBAJ&rview=1&pg=PA10&img=1&zoom=3&hl=en&sig=ACfU3U3477L46r0KxSQusJrQ6w9qxIQ70w&w=1280")
    """
    table: """
      div(style="padding: 1em;")
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
          li
            a(href="#cheevos") Cheevos
          li
            a(href="#contributors") Contributors
    """
    random: """
      div(style="padding: 1em;")
        h1 Random Thoughts
        p Don't you hate it when you're cooking something and you look at the stove clock and think it's 3:75 and you're late for your appointment but it was just the temperature and also 3:75 isn't even a real time?
        p I suggest you bone up a bit on torts before the next attempt at the bar exam.
        p Does anyone remember thepalace.com avatar based chat and virtual worlds?
        p Those spreadsheets you like are going back in style.
    """
    cheevos: """
      div(style="padding: 1em;")
        h1 Cheevos

        p No matter if you guy/girl or whatever, Cheevos impress people. It's almost like saying 'Well, I got tons of Cheevos. There are tons of people online that are interested and respect me."

        p You might be thinking 'Oh that's complete BS, I personally don't care about Cheevos when dating'. And yeah, you are probably telling the truth, but it's in your sub-concious.  Sort of like how girls always like the bad guy, but never admit it.

        p Braggin about your Cheevos sometimes makes you look conceited, but that's a good thing.  It like how celebraties look conceited because they're rolling VIP into clubs and you're stuck in line.

        p 'Brewer' asks 'What happens if you're cheevo talking at a bar, club or party and someone says they have more cheevos that you?'

        p Well, hopefully they are just hating and are lying. First look up their score with your cellphone, make sure you have a page bookmarked where you can check. If you catch them in a lie, you look even better. If they are telling the truth and have more Cheevos than you, leave. Nothing else you can do. Buy the person a drink and leave, unless you're willing to look 2nd best. If you brought a date, odds are she's going to be impressed with the higher gamer score and ditch you. Get out as soon as you can and go to some other party.

        p
          a(href="http://cheevos.com") Learn more about cheevos from Bboy360 at cheevos.com

    """
    contributors: """
      div(style="padding: 1em;")
        h1 Contributors
        ul
          li Daniel X
          li Lan
          li pketh
          li Mayor
          li and you!

        p
          a(href="#table") Return to table of contents
    """

  Object.keys(pages).forEach (pageName) ->
    value = pages[pageName]
    pages[pageName] = system.compileTemplate(value)({})

  pages.cheevos.appendChild system.Achievement.progressView()

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
    credits: ->
      displayPage "contributors"
    tableofContents: ->
      displayPage "table"

  menuBar = MenuBar
    items: parseMenu """
      [A]pps
        [T]ext Editor
        [P]ixie Paint
      #{Social.menuText}
      H[e]lp
        [T]able of Contents
        [C]redits
    """
    handlers: handlers

  windowView = Window
    title: "ZineOS Volume 1 | Issue 2 | ENTER THE DUNGEON | February 2017"
    content: container
    menuBar: menuBar.element
    width: 1228
    height: 936
    x: 32
    y: 32

  windowView.element.addEventListener "click", (e) ->
    anchor = parentElementOfType("a", e.target)

    if anchor
      next = anchor.getAttribute('href')

      if next.match /^\#/
        e.preventDefault()
        page = next.substr(1)

        displayPage(page)

  currentPage = "front"

  visited = {}

  displayPage = (page) ->
    return unless page

    visited[page] = true

    if Object.keys(visited).length is Object.keys(pages).length
      system.Achievement.unlock "Cover-2-cover 2: 2 cover 2 furious"

    if page is "vista"
      system.Achievement.unlock "Lol wut"

    emptyElement(container)
    container.appendChild(pages[page])

    currentPage = page

  displayPage currentPage

  nextPage = (n=1) ->
    pageKeys = Object.keys(pages)
    nextIndex = pageKeys.indexOf(currentPage) + n

    return pageKeys[nextIndex]

  windowView.element.addEventListener "keydown", (e) ->
    switch e.key
      when "Enter", "ArrowRight", " "
        displayPage nextPage()
      when "ArrowLeft"
        displayPage nextPage(-1)

  document.body.appendChild windowView.element

  windowView.element.tabIndex = 0
  windowView.element.focus()
