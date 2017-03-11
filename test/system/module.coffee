require "../../extensions"
Model = require "model"
Associations = require "../../system/associations"
SystemModule = require "../../system/module"

global.Hamlet = require "../../lib/hamlet"

makeSystemFS = (files) ->
  model = Model()
  model.include SystemModule, Associations

  model.fs =
    read: (path) ->
      Promise.resolve()
      .then ->
        content = files[path]
  
        throw new Error "File not found: #{path}" unless content?

        path: path
        blob: new Blob [content]

  return model

describe "System Module", ->
  it "should include modules in files async", ->
    model = makeSystemFS
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

    model.include(["/root.js", "/wat.js", "/rand.js", "/rand.js"])
    .then ([root, wat, r1, r2]) ->
      console.log root, wat, r1, r2
      assert.equal r1, r2
      assert.equal root, 'yo 2 rad hella'

  it "should throw an error when requiring a file that doesn't exist", (done) ->
    @timeout 250

    model = makeSystemFS
      "/a.js": """
        module.exports = require("./b.js")
      """

    model.include(["/a.js"])
    .catch (e) ->
      done()

  it "should wait forever when resolving circular requires", (done) ->
    model = makeSystemFS
      "/a.js": """
        module.exports = require("./b.js")
      """
      "/b.js": """
        module.exports = require("./a.js")
      """

    model.include(["/a.js"])
    .then ([a]) ->
      # Never get here
      assert false

    setTimeout ->
      done()
    , 100

  it "should work even if the file doesn't assign to module.exports", ->
    model = makeSystemFS
      "/wat.js": """
        exports.yolo = "wat";
      """

    model.include ["/wat.js"]
    .then ([wat]) ->
      assert.equal wat.yolo, "wat"

  it "should work with relative paths in subfolders", ->
    model = makeSystemFS
      "/main.js": """
        module.exports = require("./folder/a.js");
      """
      "/folder/a.js": """
        module.exports = require("./b.js");
      """
      "/folder/b.js": """
        module.exports = "b";
      """

    model.include ["/main.js"]
    .then ([main]) ->
      assert.equal main, "b"

  it "should work with absolute paths in subfolders", ->
    model = makeSystemFS
      "/main.js": """
        module.exports = require("./folder/a.js");
      """
      "/folder/a.js": """
        module.exports = require("/b.js");
      """
      "/b.js": """
        module.exports = "b";
      """

    model.include ["/main.js"]
    .then ([main]) ->
      assert.equal main, "b"

  it "should require .jadelet sources", ->
    model = makeSystemFS
      "/main.coffee": """
        template = require "./button.jadelet"

        module.exports =
          buttonTemplate: template
      """
      "/button.jadelet": """
        button(@click)= @text
      """

    model.include ["/main.coffee"]
    .then ([main]) ->
      assert typeof main.buttonTemplate is "function"
