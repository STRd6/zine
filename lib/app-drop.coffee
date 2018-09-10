Drop = require "./drop"
{fileFromDropEvent}  = require "../util"

# General drop handling for apps
module.exports = (app) ->
  Drop app.element, (e) ->
    fileFromDropEvent e
    .then (file) ->
      if file
        # Need to send file.path because annotated blobs don't keep their annotations through the structured clone
        app.send "application", "loadFile", file, file.path
