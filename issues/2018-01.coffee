Model = require "model"

AchievementStatus = require "../apps/achievement-status"
MyBriefcase = require "../apps/my-briefcase"

StoryReader = require "../apps/story-reader"

Social = require "../social/social"

fetchContent = (targetFile, sourcePath=targetFile) ->
  targetPath = "/V2/E01/#{targetFile}"

  system.readFile targetPath
  .then (file) ->
    throw new Error "File not found" unless file
  .catch ->
    system.ajax
      url: "https://danielx.whimsy.space/whimsy.space/V2E01/#{sourcePath}"
      responseType: "blob"
    .then (blob) ->
      system.writeFile targetPath, blob

module.exports = ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI
  {Achievement, ajax} = system

  system.Achievement.unlock "Volume 2: Episode 1"

  fetchContent "flyer.png"
  fetchContent "canon.md"

  launch = (App) ->
    system.attachApplication App()

  handlers = Model().include(Social).extend
    area: ->
      "2018-01"

    achievementStatus: ->
      launch AchievementStatus

    canon: ->
      system.Achievement.unlock "As fortold in the Dead Sea Scrolls"
      system.openPath "/V2/E01/canon.md"

    spaceDolphinIV: ->
      system.Achievement.unlock "Inner or outer space?"
      system.launchAppByName "Space Dolphin IV"

  menuBar = MenuBar
    items: parseMenu """
      [S]tuff
        [C]anon
        [S]pace Dolphin IV
      #{Social.menuText}
    """
    handlers: handlers

  img = document.createElement "img"
  img.src = "https://danielx.whimsy.space/whimsy.space/V2E01/flyer.png"

  windowView = Window
    title: "Whimsy.Space Volume 2 | Episode 1 | New Year Same Old You | January 2018"
    iconEmoji: "👽"
    menuBar: menuBar.element
    content: img
    width: 500 + 8
    height: 500 + 46
    x: 96
    y: 64

  windowView.element.querySelector('viewport').style.overflow = "initial"

  document.body.appendChild windowView.element
