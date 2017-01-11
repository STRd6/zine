# Compile a template from source text

module.exports = (I, self) ->
  self.extend
    compileTemplate: (source, mode="jade") ->
      templateSource = Hamlet.compile source,
        compiler: CoffeeScript
        mode: mode
        runtime: "Hamlet"
        exports: false

      Function("return " + templateSource)()
