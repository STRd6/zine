CommentFormTemplate = require "../social/comment-form"
CommentsTemplate = require "../social/comments"

Ajax = require "ajax"
ajax = Ajax()

# Includer must provide self.area() method that dictates what the comments attach to
module.exports = (I, self) ->
  {Modal} = system.UI

  self.extend
    comment: ->
      Modal.form CommentFormTemplate
        area: self.area()
      .then (data) ->
        ajax
          url: "https://whimsy-space.gomix.me/comments"
          data: JSON.stringify(data)
          headers:
            "Content-Type": "application/json"
          method: "POST"
      .then ->
        self.viewComments()

    viewComments: ->
      ajax.getJSON "https://whimsy-space.gomix.me/comments/#{self.area()}"
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

module.exports.menuText = """
S[o]cial Media
  [V]iew Comments
  [C]omment
  [L]ike
  [S]ubscribe
"""
