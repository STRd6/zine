{Observable} = require "ui"

# An object that has an observable fn of entries of [key, Observable(value)] items
module.exports = ->
  entries = {}
  update = Observable 0

  get: (name) ->
    unless entries[name]?
      entries[name] ?= Observable()
      update.increment()

    return entries[name]

  set: (name, value) ->
    if entries[name]?
      entries[name](value)
    else
      entries[name] ?= Observable value
      update.increment()

    return value

  remove: (name) ->
    unless entries[name]?
      throw new Error "Can't remove #{name}, does not exists"

    delete entries[name]
    update.increment()

    return true

  entries: Observable ->
    update() # Trigger a recomputation when entries update

    Object.keys(entries).map (name) ->
      value = entries[name]
      [name, value]
