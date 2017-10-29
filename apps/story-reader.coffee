# TODO: Kick out of core

module.exports = (opts) ->
  {title, width, height, text} = opts
  width ?= 380
  height ?= 480

  div = document.createElement "div"
  div.textContent = text
  div.style.padding = "1em"
  div.style.whiteSpace = "pre-wrap"
  div.style.textAlign = "justify"

  system.UI.Window
    title: title
    content: div
    width: width
    height: height
