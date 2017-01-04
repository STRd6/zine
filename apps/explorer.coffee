# Explorer File Browser
#
# Explore the file system like adventureres of old!

FileTemplate = require "../templates/file"

module.exports = (options={}) ->
  {path} = options
  path ?= '/'

  explorer = document.createElement "explorer"

  system.fs.list(path)
  .then (files) ->
    files.forEach (file) ->
      file.dblclick = ->
        console.log "dblclick", file
      explorer.appendChild FileTemplate file

  return explorer
