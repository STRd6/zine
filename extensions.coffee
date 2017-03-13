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

Blob::readAsDataURL = ->
  file = this

  new Promise (resolve, reject) ->
    reader = new FileReader
    reader.onload = ->
      resolve reader.result
    reader.onerror = reject
    reader.readAsDataURL(file)

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

# Event#path polyfill for Firefox
unless "path" in Event.prototype
  Object.defineProperty Event.prototype, "path",
    get: ->
      path = []
      currentElem = this.target
      while currentElem
        path.push currentElem
        currentElem = currentElem.parentElement

      if path.indexOf(window) is -1 && path.indexOf(document) is -1
        path.push(document)

      if path.indexOf(window) is -1
        path.push(window)

      path
