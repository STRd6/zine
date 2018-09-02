require "../../extensions"
Model = require "model"
SystemModule = require "../../system/module"

mocha.setup
  globals: ['amazon']

describe "System Module", ->
  it "should compile coffee", ->
    model = Model()
    model.include SystemModule

    assert.equal model.compileCoffee("alert('heyy')"), "alert('heyy');\n"
