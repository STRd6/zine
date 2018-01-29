Model = require "model"

AchievementStatus = require "../apps/achievement-status"
MyBriefcase = require "../apps/my-briefcase"

StoryReader = require "../apps/story-reader"

Social = require "../social/social"

fetchContent = (targetFile, sourcePath=targetFile) ->
  targetPath = "/V2/issue-01/#{targetFile}"

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

  # fetchContent "paranormal xmas.png"
  # fetchContent "transmission.mp3"
  fetchContent "flyer.png"
  # fetchContent "Betsy B.pdf"

  launch = (App) ->
    system.attachApplication App()

  product = (type) ->
    system.Achievement.unlock "Late stage capitalism"
    window.open "https://www.redbubble.com/people/whimsyspace/works/29661304-california-fire-palm-tree?asc=u&p=#{type}"

  handlers = Model().include(Social).extend
    area: ->
      "2018-01"

    achievementStatus: ->
      launch AchievementStatus


    myBriefcase: ->
      launch MyBriefcase

    throwPillow: ->
      product "throw-pillow"

    contrastTank: ->
      product "contrast-tank"

    journal: ->
      product "hardcover-journal"

    laptopSkin: ->
      product "laptop-skin"

    leggings: ->
      product "leggings"

    mug: ->
      product "mug"

    pouch: ->
      product "pouch"

    shirt: ->
      product "t-shirt"

    sticker: ->
      product "sticker"

    spaceDolphinIV: ->
      system.launchAppByName "Space Dolphin IV"

  menuBar = MenuBar
    items: parseMenu """
      [F]iction
        [B]etsy B
      [G]ames
        [S]pace Dolphin IV
      [S]tore
        [C]ontrastTank
        [J]ournal
        La[p]top Skin
        [M]ug
        [P]ouch
        [S]ticker
        Th[r]ow Pillow
      #{Social.menuText}
    """
    handlers: handlers

  img = document.createElement "img"
  img.src = "https://danielx.whimsy.space/whimsy.space/V2E01/flyer.png"

  windowView = Window
    title: "Whimsy.Space Volume 2 | Episode 1 | Computer Computer Revolution | January 2018"
    iconEmoji: "👽"
    menuBar: menuBar.element
    content: img
    width: 500 + 8
    height: 500 + 46
    x: 96
    y: 64

  windowView.element.querySelector('viewport').style.overflow = "initial"

  document.body.appendChild windowView.element
