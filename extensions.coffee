# Add some utility readers to the Blob API
Blob.prototype.readAsText = ->
  file = this

  new Promise (resolve, reject) ->
    reader = new FileReader
    reader.onload = ->
      resolve reader.result
    reader.onerror = reject
    reader.readAsText(file)

Blob.prototype.readAsJSON = ->
  @readAsText()
  .then JSON.parse
