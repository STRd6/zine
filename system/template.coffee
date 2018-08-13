# Compile a template from source text

module.exports = (I, self) ->
  self.extend
    templateSource: (source) ->
      return Jadelet.compile source,
        compiler: CoffeeScript
        runtime: "Jadelet" # TODO: Avoid the use of this global
        exports: false

    compileTemplate: (source) ->
      templateSource = Jadelet.compile source,
        compiler: CoffeeScript
        runtime: "Jadelet" # TODO: Avoid the use of this global
        exports: false

      Function("return " + templateSource)()
