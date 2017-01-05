require "../../extensions"
Model = require "model"
SystemModule = require "../../system/module"

describe "System Module", ->
  it "should include modules in files async", ->
    model = Model()

    model.include SystemModule

    files =
      "/test.js": """
        module.exports = 'yo';
      """
      "/root.js": """
        var test = require('./test.js');
        var test2 = require("./folder/nested.js");
        module.exports = test + " 2 rad " + test2;
      """
      "/folder/nested.js": """
        module.exports = "hella";
      """
      "/wat.js": """
        module.exports = "wat";
      """
      "/rand.js": """
        module.exports = Math.random();
      """

    model.readFile = (path) ->
      content = files[path]

      Promise.resolve new Blob [content]

    model.include(["/root.js", "/wat.js", "/rand.js", "/rand.js"])
    .then ([root, wat, r1, r2]) ->
      console.log root, wat, r1, r2
      assert.equal r1, r2
      assert.equal root, 'yo 2 rad hella'

  it "should wait forever when resolving circular requires", (done) ->
    model = Model()

    model.include SystemModule

    files =
      "/a.js": """
        module.exports = require("./b.js")
      """
      "/b.js": """
        module.exports = require("./a.js")
      """

    model.readFile = (path) ->
      content = files[path]

      Promise.resolve new Blob [content]

    model.include(["/a.js"])
    .then ([a]) ->
      # Never get here
      assert false

    setTimeout ->
      done()
    , 100

  it "should return export if present", ->
    model = Model()

    model.include SystemModule

    files =
      "/wat.js": """
        module.exports = "wat";
      """

    model.readFile = (path) ->
      content = files[path]

      Promise.resolve new Blob [content]

    model.open
      path: "/wat.js"
    .then (moduleExports) ->
      assert.equal moduleExports, "wat"

  it "should work even if the file doesn't assign to module.exports"
  ->
    model = Model()

    model.include SystemModule

    files =
      "/wat.js": """
        exports.yolo = "wat";
      """

    model.readFile = (path) ->
      content = files[path]

      Promise.resolve new Blob [content]

    model.open
      path: "/wat.js"
    .then (moduleExports) ->
      assert.equal moduleExports.yolo, "wat"
