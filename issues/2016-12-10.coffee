Notepad = require "../apps/notepad"
Spreadsheet = require "../apps/spreadsheet"

module.exports = (os) ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = os.UI

  img = document.createElement "img"
  img.src = "https://68.media.tumblr.com/6a141d69564a29ac7d4071df5d519808/tumblr_o0rbb4TA1k1urr1ryo1_500.gif"

  menuBar = MenuBar
    items: parseMenu """
      Hello
        Wait Around For A Bit
      Apps
        Notepad.exe
        MS Access 97
      Stories
        Mystery Smell
      Social Media
        Comment
        Like
        Subscribe
    """
    handlers:
      waitAroundForABit: ->
        initialMessage = "Waiting"
        progressView = Progress
          value: 0
          max: 2
          message: initialMessage

        Modal.show progressView.element,
          cancellable: false

        intervalId = setInterval ->
          newValue = progressView.value() + 1/60
          ellipsesCount = Math.floor(newValue * 4) % 4
          ellipses = [0...ellipsesCount].map ->
            "."
          .join("")
          progressView.value(newValue)
          progressView.message(initialMessage + ellipses)
          if newValue > 2
            clearInterval intervalId
            Modal.hide()
        , 15
      comment: ->
      like: ->
      subscribe: ->
      notepadexe: ->
        app = Notepad(os)
        document.body.appendChild app.element
      mSAccess97: ->
        app = Spreadsheet(os)
        document.body.appendChild app.element
      mysterySmell: ->
        div = document.createElement "div"
        div.textContent = require "../stories/mystery-smell"
        div.style.padding = "1em"
        div.style.whiteSpace = "pre-wrap"
        div.style.textAlign = "justify"
        storyWindow = Window
          title: "Mystery Smell"
          content: div
          width: 380
          height: 480
        document.body.appendChild storyWindow.element

  windowView = Window
    title: "ZineOS Volume 1 | Issue 1 | December 2016"
    content: img
    menuBar: menuBar.element
    width: 508
    height: 604
  document.body.appendChild windowView.element

