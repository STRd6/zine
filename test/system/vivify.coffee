require "../../extensions"
Model = require "model"
Vivify = require "../../system/deprecated/vivify"

makeSystemFS = (files) ->
  model = Model()
  model.include Vivify

  Object.assign model,
    readFile: (path) ->
      Promise.resolve()
      .then ->
        content = files[path]

        throw new Error "File not found: #{path}" unless content?

        blob = new Blob [content]
        blob.path = path

        return blob

  return model

describe "Vivify", ->
  it "should vivifyPrograms in files asynchronously", ->
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

    model.vivifyPrograms(["/root.js", "/wat.js", "/rand.js", "/rand.js"])
    .then ([root, wat, r1, r2]) ->
      assert.equal r1, r2
      assert.equal root, 'yo 2 rad hella'

  it "should throw an error when requiring a file that doesn't exist", (done) ->
    #@timeout 250

    model = makeSystemFS
      "/a.js": """
        module.exports = require("./b.js")
      """

    model.vivifyPrograms(["/a.js"])
    .catch (e) ->
      done()

  it "should throw an error when requiring a file that throws an error", (done) ->
    @timeout 250

    model = makeSystemFS
      "/a.js": """
        throw new Error("I am error")
      """

    model.vivifyPrograms(["/a.js"])
    .catch (e) ->
      done()

  it "should require valid json", ->
    @timeout 250

    model = makeSystemFS
      "/a.json": """
        {
          "yolo": "wat"
        }
      """

    model.vivifyPrograms(["/a.json"])
    .then ([json]) ->
      assert.equal json.yolo, "wat"

  it "should throw an error when requiring invalid json", (done) ->
    @timeout 250

    model = makeSystemFS
      "/a.json": """
        yolo: 'wat'
      """

    model.vivifyPrograms(["/a.json"])
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

    model.vivifyPrograms(["/a.js"])
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

    model.vivifyPrograms ["/wat.js"]
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

    model.vivifyPrograms ["/main.js"]
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

    model.vivifyPrograms ["/main.js"]
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

    model.vivifyPrograms ["/main.coffee"]
    .then ([main]) ->
      assert typeof main.buttonTemplate is "function"
