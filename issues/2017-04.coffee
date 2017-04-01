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
  {Achievement, ajax} = system

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

  downloadBikes = ->
    ["and-yet-they-rode-bikes.md", "infog.png", "lanes.png", "totally-a.html"].forEach (path) ->
      ajax
        url: "https://fs.whimsy.space/us-east-1:90fe8dfb-e9d2-45c7-a347-cf840a3e757f/bikes/#{path}"
        responseType: "blob"
      .then (blob) ->
        system.writeFile "issue-4/bikes/#{path}", blob

  downloadBikes()

  ajax
    url: "https://fs.whimsy.space/us-east-1:90fe8dfb-e9d2-45c7-a347-cf840a3e757f/public/music/Funkytown.mp3"
    responseType: "blob"
  .then (blob) ->
    system.writeFile "issue-4/Funkytown.mp3", blob
    blob.path = "/issue-4/Funkytown.mp3"
    system.open blob

  system.readFile "issue-4/zinecast1.mp3"
  .then ->
    ; # Zinecast exists, don't redownload
  .catch ->
    ajax
      url: "https://fs.whimsy.space/us-east-1:90fe8dfb-e9d2-45c7-a347-cf840a3e757f/public/podcasts/zinecast1.mp3"
      responseType: "blob"
    .then (blob) ->
      system.writeFile "issue-4/zinecast1.mp3", blob
      blob.path = "/issue-4/zinecast1.mp3"

  system.Achievement.unlock "Issue 4"

  handlers = Model().include(Social).extend
    area: ->
      "2017-04"

    bikes: ->
      visit "bikes"
      system.readFile "issue-4/bikes/and-yet-they-rode-bikes.md"
      .then system.open

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

    funkytown8bitRemix: ->
      system.readFile "issue-4/Funkytown.mp3"
      .then system.open

  menuBar = MenuBar
    items: parseMenu """
      [A]pps
        [C]hateau
        My [B]riefcase
      [M]usic
        [F]unkytown (8-bit Remix)
      [S]tories
        [B]ikes
        [I]zzy
        [R]esidue
      #{Social.menuText}
      [H]elp
        [A]chievement Status
    """
    handlers: handlers

  content = document.createElement "content"
  content.style = "width: 100%; height: 100%"

  img = document.createElement "img"
  img.src = "https://fs.whimsy.space/us-east-1:90fe8dfb-e9d2-45c7-a347-cf840a3e757f/public/images/708e9398a4b4bea08d7c61ff7a0f863f.gif"
  img.style = "width: 100%; height: 100%"

  windowView = Window
    title: "ZineOS Volume 1 | Issue 4 | DISCO TECH | March 2017"
    content: img
    menuBar: menuBar.element
    width: 480
    height: 600
    x: 64
    y: 64

  windowView.element.querySelector('viewport').style.overflow = "initial"

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
