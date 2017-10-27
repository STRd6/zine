AceEditor = require "../apps/text-editor"
AchievementStatus = require "../apps/achievement-status"
MyBriefcase = require "../apps/my-briefcase"

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
    💼 [M]y Briefcase
    -
    🔌 S[h]ut Down
  """

  handlers = new Proxy {
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
