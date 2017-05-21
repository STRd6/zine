module.exports = ->
  {Achievement, UI} = system
  {Window} = UI

  cheevoElement = Achievement.progressView()
  cheevoElement.style.width = "100%"
  cheevoElement.style.padding = "1em"

  Achievement.unlock "Check yo' self"

  windowView = Window
    title: "Cheevos"
    content: cheevoElement
    width: 640
    height: 480
