{extensionFor} = require "../util"

module.exports = (I, self) ->
  mimes =
    html: "text/html"
    js: "application/javascript"
    json: "application/json"
    md: "text/markdown"

  self.extend
    mimeTypeFor: (path) ->
      mimes[extensionFor(path)] or "text/plain"
