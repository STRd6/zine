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
        🍖 [C]ontrasaurus
        😭 [D]ungeon Of Sadness
      📰 [I]ssues
        1️⃣ [F]irst
        🏰 [E]nter The Dungeon
        🏬 [A]TTN: K-Mart Shoppers
        💃 [D]isco Tech
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

      appearance: ->
        system.UI.Modal.alert "TODO :)"

      aTTNKMartShoppers: ->
        system.launchIssue("2017-03")

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

      first: ->
        system.launchIssue("2016-12")

      myBriefcase: ->
        system.launchApp MyBriefcase

      pixiePaint: ->
        system.launchApp PixiePaint

      shutDown: ->
        system.UI.Modal.alert "You can never shut down ZineOS... NEVER!"

  updateStyle = ->
    height = element.getBoundingClientRect().height

    contextMenu.element.style.fontSize = "2rem"
    contextMenu.element.style.lineHeight = "1.5"
    contextMenu.element.style.bottom = "#{height}px"
    contextMenu.element.style.textAlign = "left"

  element = HomeButtonTemplate
    click: ->
      contextMenu.display
        inElement: document.body

      updateStyle()

  return element
