AceEditor = require "../apps/text-editor"
AchievementStatus = require "../apps/achievement-status"
Chateau = require "../apps/chateau"
Contrasaurus = require "../apps/contrasaurus"
PixiePaint = require "../apps/pixel"
MyBriefcase = require "../apps/my-briefcase"

HomeButtonTemplate = require "../templates/home-button"

# TODO: Restore DSAD

module.exports = ->
  {Achievement} = system
  {ContextMenu, Util:{parseMenu}} = system.UI

  launch = (App) ->
    app = App()
    system.attachApplication app

  # TODO: Generate menu from list of installed apps!

  contextMenu = ContextMenu
    items: parseMenu """
      🔨 [A]pplications
        📝 [A]ce Editor
        🍷 [C]hateau
        🎨 [P]ixie Paint
      🎮 [G]ames
        🌭 [B]ionic Hotdog
        🍖 [C]ontrasaurus
        😭 [D]ungeon Of Sadness
      📰 [I]ssues
        1️⃣ [F]irst
        🏰 [E]nter The Dungeon
        🏬 [A]TTN: K-Mart Shoppers
        💃 [D]isco Tech
        🌻 [A] May Zine
      ⚙️ [S]ettings
        📱 [A]ppearance
        💯 [C]heevos
      💼 [M]y Briefcase
      -
      🔌 S[h]ut Down
    """
    handlers:
      aceEditor: ->
        launch AceEditor

      aMayZine: ->
        system.launchIssue("2017-05")

      appearance: ->
        system.UI.Modal.alert "TODO :)"

      aTTNKMartShoppers: ->
        system.launchIssue("2017-03")

      bionicHotdog: ->
        Promise.resolve
          src: "https://danielx.net/grappl3r/"
          width: 960
          height: 540
          iconEmoji: "🌭"
          title: "Bionic Hotdog"
        .then system.iframeApp
        .then system.attachApplication

      chateau: ->
        launch Chateau

      cheevos: ->
        launch AchievementStatus

      contrasaurus: ->
        launch Contrasaurus

      discoTech: ->
        system.launchIssue("2017-04")

      enterTheDungeon: ->
        system.launchIssue("2017-02")

      "1First": ->
        system.launchIssue("2016-12")

      myBriefcase: ->
        launch MyBriefcase

      pixiePaint: ->
        launch PixiePaint

      shutDown: ->
        Achievement.unlock "Shut Down"
        system.UI.Modal.alert "You'll never shut us down! ZineOS 5ever!"

  updateStyle = (contextMenu) ->
    height = element.getBoundingClientRect().height

    contextMenu.element.style.fontSize = "1.5rem"
    contextMenu.element.style.lineHeight = "1.5"
    contextMenu.element.style.bottom = "#{height}px"
    contextMenu.element.style.textAlign = "left"

  element = HomeButtonTemplate
    click: ->
      contextMenu.display
        inElement: document.body

      updateStyle(contextMenu)

  return element
