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
    classes: ["bottoms-up"]
    items: parseMenu """
      🔨 [A]pplications
        📝 [A]ce Editor
        🍷 [C]hateau
        🎨 [P]ixie Paint
        🎮 [G]ames
          🍖 [C]ontrasaurus
          😭 [D]ungeon of Sadness
        💼 [M]y Briefcase
      ⚙️ [S]ettings
        📱 [A]ppearance
        💯 [C]heevos
    """
    handlers:
      aceEditor: ->
        system.launchApp AceEditor

      appearance: ->
        system.UI.Modal.alert "TODO :)"

      chateau: ->
        system.launchApp Chateau

      cheevos: ->
        system.launchApp AchievementStatus

      contrasaurus: ->
        system.launchApp Contrasaurus

      dungeonofSadness: ->
        system.launchApp DungeonOfSadness
  
      myBriefcase: ->
        system.launchApp MyBriefcase
  
      pixiePaint: ->
        system.launchApp PixiePaint


  updateStyle = ->
    contextMenu.element.style.fontSize = "1rem"
    contextMenu.element.style.bottom = "0px"
    contextMenu.element.style.textAlign = "left"

  element = HomeButtonTemplate
    click: ->
      contextMenu.display
        inElement: document.body

      # TODO: Update menu so we don't need to overwrite this here
      updateStyle()

  return element
