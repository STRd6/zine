Model = require "model"
Chateau = require "../apps/chateau"
Contrasaurus = require "../apps/contrasaurus"
PixiePaint = require "../apps/pixel"
Spreadsheet = require "../apps/spreadsheet"
TextEditor = require "../apps/text-editor"
MyBriefcase = require "../apps/my-briefcase"

Social = require "../social/social"

module.exports = ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI
  {Achievement, ajax} = system

  handlers = Model().include(Social).extend
    area: ->
      "2017-05"

    achievementStatus: ->
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

    chateau: ->
      app = Chateau(system)
      document.body.appendChild app.element

    myBriefcase: ->
      app = MyBriefcase()
      document.body.appendChild app.element

    pixiePaint: ->
      app = PixiePaint(system)
      document.body.appendChild app.element

    textEditor: ->
      app = TextEditor(system)
      document.body.appendChild app.element
  
  menuBar = MenuBar
    items: parseMenu """
      [A]pps
        [C]hateau
        My [B]riefcase
        [P]ixie Paint
        [T]ext Editor
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
