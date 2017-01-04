fileSeparator = "/"

normalizePath = (path) ->
  path.replace(/\/\/+/, fileSeparator) # /// -> /
  .replace(/\/[^/]*\/\.\./g, "") # /base/something/.. -> /base
  .replace(/\/\.\//g, fileSeparator) # /base/. -> /base

module.exports =
  fileSeparator: fileSeparator
  normalizePath: normalizePath
