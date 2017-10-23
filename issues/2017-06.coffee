Model = require "model"

AchievementStatus = require "../apps/achievement-status"
Contrasaurus = require "../apps/contrasaurus"
PixiePaint = require "../apps/pixel"
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
  fetchContent "tree.md"

  system.Achievement.unlock "Issue 6"

  launch = (App) ->
    system.attachApplication App()

  handlers = Model().include(Social).extend
    area: ->
      "2017-06"

    bee: ->
      system.Achievement.unlock "Bee afraid"
      system.openPath "/issue-6/bee.md"

    tree: ->
      system.Achievement.unlock "Tree story"
      system.openPath "/issue-6/tree.md"

    achievementStatus: ->
      launch AchievementStatus

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
        My [B]riefcase
        [P]ixie Paint
        [T]ext Editor
      [C]ontent
        [B]ee
        [T]ree
      #{Social.menuText}
      [H]elp
        [A]chievement Status
    """
    handlers: handlers

  img = document.createElement "img"
  img.src = "https://forgettheprotocol.com/wp-content/uploads/2017/04/09-bee-movie.w536.h357.2x.jpg"
  img.style = "width: 100%; height: 100%"

  windowView = Window
    title: "WhimsySpace Volume 1 | Episode 6 | Summertime Radness | June 2017"
    content: img
    iconEmoji: "🐝"
    menuBar: menuBar.element
    width: 536 + 8
    height: 357 + 46
    x: 64
    y: 64

  windowView.element.querySelector('viewport').style.overflow = "initial"

  document.body.appendChild windowView.element
