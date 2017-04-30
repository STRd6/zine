AceEditor = require "../apps/text-editor"
AchievementStatus = require "../apps/achievement-status"
Chateau = require "../apps/chateau"
Contrasaurus = require "../apps/contrasaurus"
DungeonOfSadness = require "../apps/dungeon-of-sadness"
PixiePaint = require "../apps/pixel"
Spreadsheet = require "../apps/spreadsheet"
MyBriefcase = require "../apps/my-briefcase"

HomeButtonTemplate = require "../templates/home-button"

module.exports = ->
  {ContextMenu, Util:{parseMenu}} = system.UI

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
        system.launchApp AceEditor

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
        .then ({element}) ->
          document.body.appendChild element

      chateau: ->
        system.launchApp Chateau

      cheevos: ->
        system.launchApp AchievementStatus

      contrasaurus: ->
        system.launchApp Contrasaurus

      discoTech: ->
        system.launchIssue("2017-04")

      dungeonOfSadness: ->
        system.launchApp DungeonOfSadness

      enterTheDungeon: ->
        system.launchIssue("2017-02")

      "1First": ->
        system.launchIssue("2016-12")

      myBriefcase: ->
        system.launchApp MyBriefcase

      pixiePaint: ->
        system.launchApp PixiePaint

      shutDown: ->
        system.UI.Modal.alert "You'll never shut us down! ZineOS 5ever!"

  updateStyle = ->
    height = element.getBoundingClientRect().height

    contextMenu.element.style.fontSize = "1.5rem"
    contextMenu.element.style.lineHeight = "1.5"
    contextMenu.element.style.bottom = "#{height}px"
    contextMenu.element.style.textAlign = "left"

  element = HomeButtonTemplate
    click: ->
      contextMenu.display
        inElement: document.body

      updateStyle()

  return element
