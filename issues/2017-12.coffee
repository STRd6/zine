Model = require "model"

AchievementStatus = require "../apps/achievement-status"
MyBriefcase = require "../apps/my-briefcase"

StoryReader = require "../apps/story-reader"

Social = require "../social/social"

fetchContent = (targetFile, sourcePath=targetFile) ->
  targetPath = "/issue-12/#{targetFile}"

  system.readFile targetPath
  .then (file) ->
    throw new Error "File not found" unless file
  .catch ->
    system.ajax
      url: "https://danielx.whimsy.space/whimsy.space/V1E12/#{sourcePath}"
      responseType: "blob"
    .then (blob) ->
      system.writeFile targetPath, blob

module.exports = ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI
  {Achievement, ajax} = system

  system.Achievement.unlock "Issue 12"

  fetchContent "Mrs Cervino.mp3"
  fetchContent "paranormal xmas.png"
  .then ->
    system.openPath "issue-12/Mrs Cervino.mp3"

  launch = (App) ->
    system.attachApplication App()

  product = (type) ->
    system.Achievement.unlock "Late stage capitalism"
    window.open "https://www.redbubble.com/people/whimsyspace/works/29495735-international-no-dabbing-symbol?asc=u&p=#{type}"

  handlers = Model().include(Social).extend
    area: ->
      "2017-12"

    achievementStatus: ->
      launch AchievementStatus

    myBriefcase: ->
      launch MyBriefcase

    investorProspectus: ->
      system.Achievement.unlock "Value Investing"

      system.attachApplication system.iframeApp
        title: "ZineOS: Beyond Time and Space"
        src: "https://docs.google.com/presentation/d/e/2PACX-1vQx21NKZad19VHx3FrMoX4Tm-RtiDWXRdf48a_um-JX8y2iQeVJRzRhyWuPjt7x3XQsyFGjih6ZrMKS/embed?start=false&loop=false&delayms=10000"
        width: 1250
        height: 739

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

    mrsCervino: ->
      system.openPath "issue-12/Mrs Cervino.mp3"

  menuBar = MenuBar
    items: parseMenu """
      [R]ecordings
        [M]rs Cervino
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
    """
    handlers: handlers

  windowView = Window
    title: "Whimsy.Space Volume 1 | Episode 12 | A Very Paranormal Christmas | December 2017"
    iconEmoji: "👽"
    menuBar: menuBar.element
    width: 452
    height: 297
    x: 96
    y: 64

  windowView.element.querySelector('viewport').style.overflow = "initial"

  document.body.appendChild windowView.element