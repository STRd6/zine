require "../../extensions"
Model = require "model"
SystemModule = require "../../system/module"

describe "System Module", ->
  it "should include modules in files async", ->
    model = Model()

    model.include SystemModule

    model.readFile = ->
      Promise.resolve new Blob ["module.exports = 'yo';"]

    assert model.include

    model.include "/test.js"
    .then (module) ->
      assert.equal module, 'yo'
