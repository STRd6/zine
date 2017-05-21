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

module.exports = ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI
  {Achievement, ajax} = system

  handlers = Model().include(Social).extend
    area: ->
      "2017-06"

    achievementStatus: ->
      system.launchApp AchievementStatus

    chateau: ->
      system.launchApp Chateau

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
      system.launchApp PixiePaint

    textEditor: ->
      system.launchApp TextEditor

  menuBar = MenuBar
    items: parseMenu """
      [A]pps
        [C]hateau
        My [B]riefcase
        [P]ixie Paint
        [T]ext Editor
      [C]ontent
        [T]ODO
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
    menuBar: menuBar.element
    width: 640
    height: 360
    x: 64
    y: 64

  windowView.element.querySelector('viewport').style.overflow = "initial"

  document.body.appendChild windowView.element
