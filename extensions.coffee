# Pretend Jadelet is a real package
PACKAGE.dependencies["!jadelet"] =
  entryPoint: "main"
  distribution:
    main: PACKAGE.distribution["lib/jadelet.min"]

# Extend JSON with toBlob method
JSON.toBlob ?= (object) ->
  new Blob [JSON.stringify(object)], type: "application/json; charset=utf-8"

# Add some utility readers to the Blob API
Blob::readAsText = ->
  file = this

  new Promise (resolve, reject) ->
    reader = new FileReader
    reader.onload = ->
      resolve reader.result
    reader.onerror = reject
    reader.readAsText(file)

Blob::getURL = ->
  Promise.resolve URL.createObjectURL(this)

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

# BlobSham interface must implement getURL and readAs* methods

# Load an image from a blob returning a promise that is fulfilled with the
# loaded image or rejected with an error
Image.fromBlob = (blob) ->
  blob.getURL()
  .then (url) ->
    new Promise (resolve, reject) ->
      img = new Image
      img.onload = ->
        resolve img
      img.onerror = reject

      img.src = url

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
