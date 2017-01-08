# Add some utility readers to the Blob API
Blob::readAsText = ->
  file = this

  new Promise (resolve, reject) ->
    reader = new FileReader
    reader.onload = ->
      resolve reader.result
    reader.onerror = reject
    reader.readAsText(file)

Blob::readAsJSON = ->
  @readAsText()
  .then JSON.parse

# Load an image from a blob returning a promise that is fulfilled with the
# loaded image or rejected with an error
Image.fromBlob = (blob) ->
  new Promise (resolve, reject) ->
    img = new Image
    img.onload = ->
      resolve img
    img.onerror = reject

    img.src = URL.createObjectURL blob

FileList::forEach ?= (args...) ->
  Array::forEach.apply(this, args)
