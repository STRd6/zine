Model = require "model"

AchievementStatus = require "../apps/achievement-status"
MyBriefcase = require "../apps/my-briefcase"

StoryReader = require "../apps/story-reader"

Social = require "../social/social"

module.exports = ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI
  {Achievement, ajax} = system

  ggPath = "issue-5/gleep-glorp.m4a"

  system.readFile ggPath
  .then (file) ->
    throw new Error "File not found" unless file
  .catch ->
    ajax
      url: "https://fs.whimsy.space/us-east-1:90fe8dfb-e9d2-45c7-a347-cf840a3e757f/public/hao/gleep-glorp.m4a"
      responseType: "blob"
    .then (blob) ->
      system.writeFile ggPath, blob

  handlers = Model().include(Social).extend
    area: ->
      "2017-05"

    achievementStatus: ->
      system.launchApp AchievementStatus

    crescent: ->
      app = StoryReader
        text: require "../stories/crescent"
        title: "Crescent"

      document.body.appendChild app.element

    gleepGlorp: ->
      system.openPath ggPath

    marigold: ->
      app = StoryReader
        text: require "../stories/marigold"
        title: "Marigold"

      document.body.appendChild app.element

    myBriefcase: ->
      system.launchApp MyBriefcase

    pixiePaint: ->
      system.launchAppByName("Pixie Paint")

    textEditor: ->
      system.launchAppByName "Notepad"

  menuBar = MenuBar
    items: parseMenu """
      [A]pps
        My [B]riefcase
        [P]ixie Paint
        [T]ext Editor
      [C]ontent
        [C]rescent
        [G]leep Glorp
        [M]arigold
      #{Social.menuText}
      [H]elp
        [A]chievement Status
    """
    handlers: handlers

  img = document.createElement "img"
  img.src = "https://i.imgur.com/hKOGoex.jpg"
  img.style = "width: 100%; height: 100%"

  windowView = Window
    title: "ZineOS Volume 1 | Issue 5 | A May Zine | May 2017"
    content: img
    menuBar: menuBar.element
    width: 640
    height: 360
    x: 64
    y: 64

  windowView.element.querySelector('viewport').style.overflow = "initial"

  document.body.appendChild windowView.element
