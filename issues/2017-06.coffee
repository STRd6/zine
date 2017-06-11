Model = require "model"

AchievementStatus = require "../apps/achievement-status"
Chateau = require "../apps/chateau"
Contrasaurus = require "../apps/contrasaurus"
PixiePaint = require "../apps/pixel"
Spreadsheet = require "../apps/spreadsheet"
TextEditor = require "../apps/text-editor"
MyBriefcase = require "../apps/my-briefcase"

StoryReader = require "../apps/story-reader"

Social = require "../social/social"

fetchContent = (targetFile, sourcePath=targetFile) ->
  targetPath = "/issue-6/#{targetFile}"

  system.readFile targetPath
  .then (file) ->
    throw new Error "File not found" unless file
  .catch ->
    system.ajax
      url: "https://fs.whimsy.space/us-east-1:90fe8dfb-e9d2-45c7-a347-cf840a3e757f/public/#{sourcePath}"
      responseType: "blob"
    .then (blob) ->
      system.writeFile targetPath, blob

module.exports = ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI
  {Achievement, ajax} = system

  fetchContent "bee.md"

  system.Achievement.unlock "Issue 6"

  launch = (App) ->
    system.attachApplication App()

  handlers = Model().include(Social).extend
    area: ->
      "2017-06"

    bee: ->
      system.Achievement.unlock "Bee afraid"
      system.openPath "/issue-6/bee.md"

    achievementStatus: ->
      launch AchievementStatus

    chateau: ->
      launch Chateau

    crescent: ->
      app = StoryReader
        text: require "../stories/crescent"
        title: "Crescent"

      document.body.appendChild app.element

    marigold: ->
      app = StoryReader
        text: require "../stories/marigold"
        title: "Marigold"

      document.body.appendChild app.element

    myBriefcase: ->
      launch MyBriefcase

    pixiePaint: ->
      launch PixiePaint

    textEditor: ->
      launch TextEditor

  menuBar = MenuBar
    items: parseMenu """
      [A]pps
        [C]hateau
        My [B]riefcase
        [P]ixie Paint
        [T]ext Editor
      [C]ontent
        [B]ee
      #{Social.menuText}
      [H]elp
        [A]chievement Status
    """
    handlers: handlers

  img = document.createElement "img"
  img.src = "https://i.imgur.com/hKOGoex.jpg"
  img.style = "width: 100%; height: 100%"

  windowView = Window
    title: "WhimsySpace Volume 1 | Episode 6 | Summertime Radness | June 2017"
    content: img
    iconEmoji: "🐝"
    menuBar: menuBar.element
    width: 640
    height: 360
    x: 64
    y: 64

  windowView.element.querySelector('viewport').style.overflow = "initial"

  document.body.appendChild windowView.element
