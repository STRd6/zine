module.exports = (element, handler) ->
  cancel = (e) ->
    e.preventDefault()
    return false

  element.addEventListener "dragover", cancel
  element.addEventListener "dragenter", cancel
  element.addEventListener "drop", (e) ->
    e.preventDefault()
    handler(e)
    return false
