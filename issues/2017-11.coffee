Model = require "model"

AchievementStatus = require "../apps/achievement-status"
MyBriefcase = require "../apps/my-briefcase"

StoryReader = require "../apps/story-reader"

Social = require "../social/social"

fetchContent = (targetFile, sourcePath=targetFile) ->
  targetPath = "/issue-10/#{targetFile}"

  system.readFile targetPath
  .then (file) ->
    throw new Error "File not found" unless file
  .catch ->
    system.ajax
      url: "https://danielx.whimsy.space/whimsy.space/V1E11/#{sourcePath}"
      responseType: "blob"
    .then (blob) ->
      system.writeFile targetPath, blob

module.exports = ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI
  {Achievement, ajax} = system

  system.Achievement.unlock "Issue 11"

  launch = (App) ->
    system.attachApplication App()
  
  product = (type) ->
    system.Achievement.unlock "Late stage capitalism"
    window.open "https://www.redbubble.com/people/whimsyspace/works/29495735-international-no-dabbing-symbol?p=#{type}"

  handlers = Model().include(Social).extend
    area: ->
      "2017-11"

    achievementStatus: ->
      launch AchievementStatus

    myBriefcase: ->
      launch MyBriefcase

    aLineDress: ->
      product "a-line-dress"

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
    
    throwPillow: ->
      product "throw-pillow"

  menuBar = MenuBar
    items: parseMenu """
      [G]ames
      [S]tore
        [A] Line Dress
        [C]ontrastTank
        [J]ournal
        [L]eggings
        La[p]top Skin
        [M]ug
        [P]ouch
        [S]ticker
        [T]-Shirt -> shirt
        Th[r]ow Pillow
      #{Social.menuText}
      [H]elp
        [A]chievement Status
    """
    handlers: handlers

  iframe = document.createElement "iframe"
  iframe.src = "https://www.youtube.com/embed/Mxstehc-YTk?autoplay=1&loop=1&controls=0&showinfo=0&playlist=Mxstehc-YTk&iv_load_policy=3"
  iframe.style = "width: 100%; height: 100%"

  windowView = Window
    title: "Whimsy.Space Volume 1 | Episode 11 | Do you dab? | November 2017"
    content: iframe
    iconEmoji: "💃"
    menuBar: menuBar.element
    width: 452
    height: 297
    x: 96
    y: 64

  windowView.element.querySelector('viewport').style.overflow = "initial"

  document.body.appendChild windowView.element
