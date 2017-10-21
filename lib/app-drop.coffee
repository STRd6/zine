Drop = require "./drop"
{fileFromDropEvent}  = require "../util"

# General drop handling for apps
module.exports = (app) ->
  {element} = app

  Drop element, (e) ->
    {handlers} = app

    fileFromDropEvent e
    .then (file) ->
      if file
        path = file.path

        app.send "loadFile", file, path
        .then ->
          if path
            handlers.currentPath path
          else
            handlers.currentPath null
