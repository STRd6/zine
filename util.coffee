fileSeparator = "/"

normalizePath = (path) ->
  path.replace(/\/\/+/, fileSeparator) # /// -> /
  .replace(/\/[^/]*\/\.\./g, "") # /base/something/.. -> /base
  .replace(/\/\.\//g, fileSeparator) # /base/. -> /base

# NOTE: Allows paths like '../..' to go above the base path
absolutizePath = (base, relativePath) ->
  normalizePath "/#{base}/#{relativePath}"

module.exports =
  emptyElement: (element) ->
    while element.lastChild
      element.removeChild element.lastChild

  fileSeparator: fileSeparator
  normalizePath: normalizePath
  absolutizePath: absolutizePath

  parentElementOfType: (tagname, element) ->
    tagname = tagname.toLowerCase()

    if element.nodeName.toLowerCase() is tagname
      return element

    while element = element.parentNode
      if element.nodeName.toLowerCase() is tagname
        return element
