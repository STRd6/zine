AceEditor = require "../apps/text-editor"

HomeButtonTemplate = require "../templates/home-button"

module.exports = ->
  {ContextMenu, Util:{parseMenu}} = system.UI

  contextMenu = ContextMenu
    items: parseMenu """
      [A]pplications
        [C]reate
          [A]ce Editor
          [P]ixie Paint
        [G]ames
          [C]ontrasaurus
          [D]ungeon of Sadness
      [S]ettings
        [A]ppearance
    """
    handlers:
      aceEditor: ->
        system.launchApp AceEditor

  updateStyle = ->
    contextMenu.element.style.fontSize = "1rem"
    contextMenu.element.style.bottom = "0px"
    contextMenu.element.style.textAlign = "left"

  element = HomeButtonTemplate
    click: ->
      contextMenu.display
        inElement: element

      # TODO: Update menu so we don't need to overwrite this here
      updateStyle()

  return element
