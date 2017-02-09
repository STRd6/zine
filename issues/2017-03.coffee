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

  system.Achievement.unlock "Issue 3"

  handlers = Model().include(Social).extend
    area: ->
      "2017-03"
    mSAccess97: ->
      app = Spreadsheet(system)
      document.body.appendChild app.element

    chateau: ->
      app = Chateau(system)
      document.body.appendChild app.element

  menuBar = MenuBar
    items: parseMenu """
      [A]pps
        [C]hateau
      #{Social.menuText}
    """
    handlers: handlers

  windowView = Window
    title: "ZineOS Volume 1 | Issue 3 | ATTN: K-Mart Shoppers | March 2017"
    content: null
    menuBar: menuBar.element
    width: 800
    height: 600
    x: 32
    y: 32

  document.body.appendChild windowView.element
