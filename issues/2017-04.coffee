Model = require "model"
Chateau = require "../apps/chateau"
Contrasaurus = require "../apps/contrasaurus"
PixiePaint = require "../apps/pixel"
Spreadsheet = require "../apps/spreadsheet"
TextEditor = require "../apps/text-editor"
MyBriefcase = require "../apps/my-briefcase"

Social = require "../social/social"

{parentElementOfType, emptyElement} = require "../util"

module.exports = ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI
  {Achievement} = system

  visitedAreas =
    bikes: false
    izzy: false
    residue: false
    chateau: false
    cheevo: false
    briefcase: false

  visit = (area) ->
    visitedAreas[area] = true

    visitedAll = Object.keys(visitedAreas).every (key) ->
      visitedAreas[key]

    if visitedAll
      Achievement.unlock "Cover-2-cover 4: Fast & Furious"

  system.writeFile "issue-4/izzy.txt", new Blob [require "../stories/izzy"], type: "text/plain"
  system.writeFile "issue-4/residue.txt", new Blob [require "../stories/residue"], type: "text/plain"

  system.Achievement.unlock "Issue 4"

  handlers = Model().include(Social).extend
    area: ->
      "2017-04"

    chateau: ->
      visit "chateau"
      app = Chateau(system)
      document.body.appendChild app.element

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

    myBriefcase: ->
      visit "briefcase"
      app = MyBriefcase()
      document.body.appendChild app.element

    izzy: ->
      Achievement.unlock "Izzy"
      visit "izzy"
      storyWindow = StoryWindow("Izzy", require("../stories/izzy"))

      document.body.appendChild storyWindow.element

    residue: ->
      Achievement.unlock "Residue"
      visit "residue"

      storyWindow = StoryWindow("Residue", require("../stories/residue"))

      document.body.appendChild storyWindow.element

  menuBar = MenuBar
    items: parseMenu """
      [A]pps
        [C]hateau
        My [B]riefcase
      [M]usic
        [F]unkytown (8-bit Remix)
      [S]tories
        [I]zzy
        [R]esidue
      #{Social.menuText}
      [H]elp
        [A]chievement Status
    """
    handlers: handlers

  windowView = Window
    title: "ZineOS Volume 1 | Issue 3 | ATTN: K-Mart Shoppers | March 2017"
    content: undefined
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
