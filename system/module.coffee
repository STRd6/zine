module.exports = (I, self) ->

  # System modules table
  modules = {}

  ###
  Load a module from a file in the file system.

  Additional properties such as a reference to the global object and some metadata
  are exposed.

  Returns a promise that is fulfilled when the module assigns its exports, or
  rejected on error.
  ###
  fileSeparator = "/"

  loadModule = (content, path) ->
    new Promise (resolve, reject) ->
      program = annotateSourceURL content, path
      dirname = path.split(fileSeparator)[0...-1].join(fileSeparator)

      # May need to scan for a module.exports to see if it is the kind of
      # module that exports things vs just plain side effects code
      module =
        path: dirname

      # Use a defineProperty setter on module.exports to trigger when the module
      # successfully exports because it can all be async madness.
      exports = {}
      Object.defineProperty module, "exports",
        get: ->
          exports
        set: (newValue) ->
          exports = newValue
          # Trigger complete
          resolve(module)

      # TODO: Apply relative path wrapper for system.include
      context =
        system: self
        global: global
        module: module
        exports: module.exports
        __filename: path
        __dirname: dirname

      args = Object.keys(context)
      values = args.map (name) -> context[name]

      try
        Function(args..., program).apply(module, values)
      catch e
        reject e

  Object.assign self,
    # still experimenting with the API
    # Async include in the vein of require.js
    # it's horrible but seems necessary
    include: (moduleIdentifiers...) ->
      Promise.all moduleIdentifiers.map (identifier) ->
        # Only allow absolute and system modules, relative modules can be handled
        # by wrapping this when exposing system to scripts

        # If a file, read and execute the file
        # If a system module, return the module
        # TODO: Make sure we handle normalizing paths correctly
        if identifier.indexOf("/") is 0
          self.readFile(identifier)
          .then (file) ->
            file.readAsText()
          .then (sourceProgram) ->
            loadModule sourceProgram, identifier
          .then (module) ->
            module.exports
        else
          module = modules[identifier]

          if module
            Promise.resolve module
          else
            Promise.reject new Error "System module not found: #{module}"

annotateSourceURL = (program, path) ->
  """
    #{program}
    //# sourceURL=#{path}
  """
