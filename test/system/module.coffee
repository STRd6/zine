require "../../extensions"
Model = require "model"
SystemModule = require "../../system/module"

mocha.setup
  globals: ['amazon']

makeSystemFS = (files) ->
  model = Model()
  model.include SystemModule

  Object.assign model,
    readAsText: (path) ->
      if content = files[path]
        return Promise.resolve(content)
      else
        return Promise.reject new Error "File not found at: #{path}"
    readFile: (path) ->
      Promise.resolve()
      .then ->
        content = files[path]

        throw new Error "File not found: #{path}" unless content?

        blob = new Blob [content]
        blob.path = path

        return blob

  return model

describe "System Module", ->
  it "should compile coffee", ->
    model = Model()
    model.include SystemModule

    assert.equal model.compileCoffee("alert('heyy')"), "alert('heyy');\n"

  it "should find dependencies in source code", ->
    model = Model()
    model.include SystemModule

    assert model.findDependencies("""
      require("system-client");
      external.require('something else')
    """)[0] is "system-client"

  it "should package programs into json packages", ->
    model = makeSystemFS
      "/test.coffee": """
        require("system-client")
      """
      "/pixie.cson": """
        entryPoint: "main"
        dependencies:
          "system-client": "STRd6/system-client:master"
        remoteDependencies: [
          "https://jquery.biz/jquery.json.js"
        ]
      """
      "/main.coffee": """
        alert('heyy')
      """

    model.packageProgram("/test.coffee")
    .then (pkg) ->
      assert pkg.dependencies["system-client"], "Package should include system-client as a dependency"
      assert pkg.remoteDependencies[0], "It shoud have remote dependencies"
      assert.equal pkg.entryPoint, "test"

  it "should package pixie.cson into a usable package", ->
    model = makeSystemFS
      "/test.coffee": """
        require("system-client")
      """
      "/pixie.cson": """
        entryPoint: "main"
        dependencies:
          "system-client": "STRd6/system-client:master"
        remoteDependencies: [
          "https://jquery.biz/jquery.json.js"
        ]
      """
      "/main.coffee": """
        alert('heyy')
      """

    model.packageProgram("/pixie.cson")
    .then (pkg) ->
      # Note: we currently don't fetch dependencies that aren't referenced
      assert !pkg.dependencies["system-client"], "Package shouldn't include system-client as a dependency"
      assert pkg.remoteDependencies[0], "It shoud have remote dependencies"
      assert.equal pkg.entryPoint, "main"

  it "should package templates and dependencies", ->
    model = makeSystemFS
      "/main.coffee": """
        template = require "./app"
      """
      "/app.jadelet": """
        app
          h1 hello
          p Rad!
      """

    model.packageProgram("/main.coffee")
    .then (pkg) ->
      console.log pkg
      # Note: we currently don't fetch dependencies that aren't referenced
      assert pkg.dependencies["!jadelet"], "Package shouldn include special Jadelet dependency"
      assert.equal pkg.entryPoint, "main"
