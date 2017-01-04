module.exports = (I, self) ->
  ###
  Load a module from a file in the file system.

  Additional properties such as a reference to the global object and some metadata
  are exposed.

  Returns a promise that is fulfilled when the module assigns its exports, or
  rejected on error.
  ###
  fileSeparator = "/"

  normalizePath = (path) ->
    path.replace(/\/\/+/, fileSeparator) # /// -> /
    .replace(/\/[^/]*\/\.\./g, "") # /base/something/.. -> /base
    .replace(/\/\.\//g, fileSeparator) # /base/. -> /base

  # Wrap program in async include wrapper
  rewriteRequires = (program) ->
    id = 0
    namePrefix = "__req"
    requires = {}

    # rewrite requires
    rewrittenProgram = program.replace /require\(['"]([^'"]+)['"]\)/g, (match, key) ->
      if requires[key]
        tmpVar = requires[key]
      else
        tmpVar = "#{namePrefix}#{id}"
        id += 1
        requires[key] = tmpVar

      return tmpVar

    tmpVars = Object.keys(requires).map (name) ->
      requires[name]

    requirePaths = Object.keys(requires)
    requirePaths = requirePaths

    """
      system.include(#{JSON.stringify(requirePaths)})
      .then(function(__reqResults) {
      (function(#{tmpVars.join(', ')}){
      #{rewrittenProgram}
      }).apply(this, __reqResults);
      });
    """

  loadModule = (content, path) ->
    new Promise (resolve, reject) ->
      program = annotateSourceURL(rewriteRequires(content), path)
      dirname = path.split(fileSeparator)[0...-1].join(fileSeparator) or fileSeparator

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

      localSystem = Object.assign {}, self,
        include: (moduleIdentifiers) ->
          self.include moduleIdentifiers.map (identifier) ->
            normalizePath dirname + identifier

      # TODO: Apply relative path wrapper for system.include
      context =
        system: localSystem
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
        console.error e
        reject e

  Object.assign self,
    # still experimenting with the API
    # Async include in the vein of require.js
    # it's horrible but seems necessary
    include: (moduleIdentifiers) ->
      Promise.all moduleIdentifiers.map (identifier) ->
        # Read and execute the file
        self.readFile(identifier)
        .then (file) ->
          file.readAsText()
        .then (sourceProgram) ->
          loadModule sourceProgram, identifier
        .then (module) ->
          module.exports

annotateSourceURL = (program, path) ->
  """
    #{program}
    //# sourceURL=#{path}
  """
