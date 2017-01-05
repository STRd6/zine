fileSeparator = "/"

normalizePath = (path) ->
  path.replace(/\/\/+/, fileSeparator) # /// -> /
  .replace(/\/[^/]*\/\.\./g, "") # /base/something/.. -> /base
  .replace(/\/\.\//g, fileSeparator) # /base/. -> /base

module.exports =
  emptyElement: ->
    while element.lastChild
      element.removeChild element.lastChild

  fileSeparator: fileSeparator
  normalizePath: normalizePath
