require "../../extensions"
Model = require "model"
SystemModule = require "../../system/module"

describe "System Module", ->
  it "should include modules in files async", ->
    model = Model()

    model.include SystemModule

    files =
      "/test.js": """
        console.log('in test.js');
        module.exports = 'yo';
      """
      "/root.js": """
        console.log('in root.js', require);
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
