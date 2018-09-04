module.exports = (fn) ->
  cache = {}

  return (key) ->
    unless cache[key]
      cache[key] = fn.apply(this, arguments)

      # Remove cache and propagate error
      cache[key].catch (e) ->
        delete cache[key]
        throw e

    return cache[key]
