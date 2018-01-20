AchievementStatus = require "../apps/achievement-status"

HomeButtonTemplate = require "../templates/home-button"

{Observable} = require "ui"

module.exports = (system) ->
  {Achievement} = system
  {ContextMenu, Util:{parseMenu}} = system.UI

  launch = (App) ->
    app = App()
    system.attachApplication app

  extraItems = parseMenu """
    ⚙️ [S]ettings
      📱 [A]ppearance
      💯 [C]heevos
    💼 [M]y Briefcase -> briefcase
    🖳 danielx.net -> danielxNet
    ❔ [A]bout
    -
    🔌 S[h]ut Down
  """

  AppearanceTemplate = require "../templates/appearance"
  appearanceModel =
    value: Observable """
      body > explorer {
        background-color: rgb(103, 58, 183);
        background-image: url("https://danielx.whimsy.space/whimsy.space/V2E01/disco.png");
        background-repeat: repeat;
      }
    """

  customStyle = document.createElement 'style'
  appearanceModel.value.observe (newValue) ->
    customStyle.textContent = newValue

  document.head.appendChild customStyle

  handlers = new Proxy {
    about: ->
      system.UI.Modal.alert "Ha! You think the secrets of the universe will reveal themselves so easily?"
    appearance: ->
      system.UI.Modal.show AppearanceTemplate appearanceModel
    briefcase: ->
      system.openBriefcase()
    cheevos: ->
      launch AchievementStatus
    danielxNet: ->
      system.launchAppByAppData
        title: "danielx.net"
        icon: "🖳"
        src: "https://danielx.net"
    shutDown: ->
      Achievement.unlock "Shut Down"
      system.UI.Modal.alert "You'll never shut us down!"
  },
    get: (target, property, receiver) ->
      target[property] ?= ->
        system.launchAppByName property

  decorations =
    Applications: "🔨"
    Games: "🎮"
    Issues: "📰"

  decorate = (category) ->
    "#{decorations[category] or ""} #{category}"

  appDataToItems = (data) ->
    categories = {}

    data.forEach (datum) ->
      {category} = datum

      category ?= "Applications"
      (categories[category] ?= []).push "#{datum.icon or ""} #{datum.name} -> #{datum.name}"

    Object.keys(categories).sort().map (category) ->
      [decorate(category), categories[category]]
    .concat extraItems

  items = Observable []
  system.appData.observe (data) ->
    items appDataToItems data

  contextMenu = ContextMenu
    items: items
    handlers: handlers

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
