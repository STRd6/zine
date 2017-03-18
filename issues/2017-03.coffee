Model = require "model"
Chateau = require "../apps/chateau"
Contrasaurus = require "../apps/contrasaurus"
PixiePaint = require "../apps/pixel"
Spreadsheet = require "../apps/spreadsheet"
TextEditor = require "../apps/text-editor"

Social = require "../social/social"

{parentElementOfType, emptyElement} = require "../util"

module.exports = ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI
  {Achievement} = system

  visitedAreas =
    blue: false
    csaur: false
    chateau: false
    cheevo: false
    evan: false

  visit = (area) ->
    visitedAreas[area] = true

    visitedAll = Object.keys(visitedAreas).every (key) ->
      visitedAreas[key]

    if visitedAll
      Achievement.unlock "Cover-2-cover 3: Tokyo Drift"

  system.writeFile "issue-3/blue-light-special.txt", new Blob [require "../stories/blue-light-special"], type: "text/plain"

  system.Achievement.unlock "Issue 3"

  handlers = Model().include(Social).extend
    area: ->
      "2017-03"

    mSAccess97: ->
      app = Spreadsheet(system)
      document.body.appendChild app.element

    chateau: ->
      visit "chateau"
      app = Chateau(system)
      document.body.appendChild app.element

    contrasaurus: ->
      visit "csaur"
      document.body.appendChild Contrasaurus(system).element

    achievementStatus: ->
      visit "cheevo"
      cheevoElement = system.Achievement.progressView()
      cheevoElement.style.width = "100%"
      cheevoElement.style.padding = "1em"

      system.Achievement.unlock "Check yo' self"

      windowView = Window
        title: "Cheevos"
        content: cheevoElement
        width: 640
        height: 480

      document.body.appendChild windowView.element

    evanAndMore: ->
      visit "evan"
      url = "https://s3.amazonaws.com/whimsyspace-databucket-1g3p6d9lcl6x1/danielx/IMG_9794.JPG"
      img = document.createElement "img"
      img.src = url

      {element} = system.UI.Window
        title: "Evan And More"
        content: img
        width: 600
        height: 480

      document.body.appendChild element

    blueLightSpecial: ->
      Achievement.unlock "Blue light special"
      visit "blue"

      storyWindow = StoryWindow("Blue Light Special", require("../stories/blue-light-special"))

      document.body.appendChild storyWindow.element

  menuBar = MenuBar
    items: parseMenu """
      [A]pps
        [C]hateau
        Contra[s]aurus
      [S]tories
        [B]lue Light Special
        [E]van And More
      #{Social.menuText}
      [H]elp
        [A]chievement Status
    """
    handlers: handlers

  kmartGif = document.createElement "img"
  kmartGif.src = "http://media.boingboing.net/wp-content/uploads/2015/07/m66DBJ.gif"
  kmartGif.style = "width: 100%; height: 100%"

  windowView = Window
    title: "ZineOS Volume 1 | Issue 3 | ATTN: K-Mart Shoppers | March 2017"
    content: kmartGif
    menuBar: menuBar.element
    width: 800
    height: 600
    x: 32
    y: 32

  document.body.appendChild windowView.element

StoryWindow = (title, text) ->
  div = document.createElement "div"
  div.textContent = text
  div.style.padding = "1em"
  div.style.whiteSpace = "pre-wrap"
  div.style.textAlign = "justify"

  system.UI.Window
    title: title
    content: div
    width: 380
    height: 480
