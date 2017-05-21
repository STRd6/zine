# Open a feedback form
module.exports = ->
  iframe = document.createElement "iframe"
  iframe.src = "https://docs.google.com/forms/d/e/1FAIpQLSfAK8ZYmMd4-XsDqyTK4soYGWApGD9R33nReuqwG-TxjXaGFg/viewform?embedded=true"

  Window = system.UI.Window

  windowView = Window
    title: "Whimsy Space Feedback"
    content: iframe
    menuBar: null
    width: 600
    height: 500

  system.Achievement.unlock "We value your input"

  document.body.appendChild windowView.element
