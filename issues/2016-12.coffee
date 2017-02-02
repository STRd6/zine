Notepad = require "../apps/notepad"
CommentFormTemplate = require "../social/comment-form"
CommentsTemplate = require "../social/comments"

Ajax = require "ajax"
ajax = Ajax()

issueTag = "2016-12"

module.exports = ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI

  system.Achievement.unlock "Issue 1"

  img = document.createElement "img"
  img.src = "https://68.media.tumblr.com/6a141d69564a29ac7d4071df5d519808/tumblr_o0rbb4TA1k1urr1ryo1_500.gif"

  handlers =
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
          system.Achievement.unlock "No rush"
          clearInterval intervalId
          Modal.hide()
      , 15
    comment: ->
      Modal.form CommentFormTemplate
        area: issueTag
      .then (data) ->
        ajax
          url: "https://whimsy-space.gomix.me/comments"
          data: JSON.stringify(data)
          headers:
            "Content-Type": "application/json"
          method: "POST"
      .then ->
        handlers.viewComments()

    viewComments: ->
      ajax.getJSON "https://whimsy-space.gomix.me/comments/#{issueTag}"
      .then (data) ->
        data = data.reverse()

        if data.length is 0
          data = [{
            body: "no comments"
            author: "mgmt"
          }]

        Modal.show CommentsTemplate data

    like: ->
      Modal.alert "I like you too, but we don't have a facebook or anything yet :)"
    subscribe: ->
      require("../mailchimp").show()
    notepadexe: ->
      app = Notepad()
      document.body.appendChild app.element
    mSAccess97: ->
      app = Spreadsheet()
      document.body.appendChild app.element
    mysterySmell: ->
      system.Achievement.unlock "Cover-2-cover"

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

  menuBar = MenuBar
    items: parseMenu """
      [H]ello
        [W]ait Around For A Bit
      [A]pps
        [N]otepad.exe
      [S]tories
        [M]ystery Smell
      S[o]cial Media
        [V]iew Comments
        [C]omment
        [L]ike
        [S]ubscribe
    """
    handlers: handlers

  windowView = Window
    title: "ZineOS Volume 1 | Issue 1 | December 2016"
    content: img
    menuBar: menuBar.element
    width: 508
    height: 604

  document.body.appendChild windowView.element
