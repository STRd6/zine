# Compile a template from source text

module.exports = (I, self) ->
  self.extend
    compileTemplate: (source) ->
      templateSource = Jadelet.compile source,
        compiler: CoffeeScript
        runtime: "Jadelet" # TODO: Avoid the use of this global
        exports: false

      Function("return " + templateSource)()
