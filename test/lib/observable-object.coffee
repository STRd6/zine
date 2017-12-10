ObservableObject = require "/lib/observable-object"

describe "ObservableObject", ->
  it "should observe properties", ->
    o = ObservableObject()

    o.get("cool").observe (v) ->
      console.log "cool", v

    o.entries.observe console.log
    o.set "cool", "wat"
    o.set "jawsome", "2jawsome"
    o.remove "cool"
