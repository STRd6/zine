fileSeparator = "/"

normalizePath = (path) ->
  path.replace(/\/\/+/, fileSeparator) # /// -> /
  .replace(/\/[^/]*\/\.\./g, "") # /base/something/.. -> /base
  .replace(/\/\.\//g, fileSeparator) # /base/. -> /base

module.exports =
  emptyElement: (element) ->
    while element.lastChild
      element.removeChild element.lastChild

  fileSeparator: fileSeparator
  normalizePath: normalizePath

  parentElementOfType: (tagname, element) ->
    tagname = tagname.toLowerCase()

    if element.nodeName.toLowerCase() is tagname
      return element

    while element = element.parentNode
      if element.nodeName.toLowerCase() is tagname
        return element
