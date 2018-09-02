###
Vivify is a deprecated method of reading an individual file and attempting to
find and wrap its requires asynchronously. It is deprecated because it is fairly
complicated and our current preference is to create a static package that we can
run instead of magically asynchronously pulling and wrapping things.
###

{
  absolutizePath
  fileSeparator
  isAbsolutePath
  isRelativePath
} = require "../../util"

module.exports = (I, self) ->
  
  self.include(require("../module"))

  ###
  Load a module from a file in the file system.

  Additional properties such as a reference to the global object and some metadata
  are exposed.

  Returns a promise that is fulfilled when the module assigns its exports, or
  rejected on error.

  Caches modules so mutual includes don't get re-run per include root.

  Circular includes will never reslove
  # TODO: Fail early on circular includes, challenging because of async

  # Currently can require
  # js, coffee, jadelet, json, cson

  # Requiring other file types returns a Blob

  ###
  loadModule = (content, path, state) ->
    new Promise (resolve, reject) ->
      program = annotateSourceURL(rewriteRequires(content), path)
      dirname = path.split(fileSeparator)[0...-1].join(fileSeparator) or fileSeparator

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

      # Apply relative path wrapper for system.vivifyPrograms
      localSystem = Object.assign {}, self,
        vivifyPrograms: (moduleIdentifiers) ->
          absoluteIdentifiers = moduleIdentifiers.map (identifier) ->
            if isAbsolutePath(identifier)
              absolutizePath "/", identifier
            else if isRelativePath(identifier)
              absolutizePath dirname, identifier
            else
              identifier

          self.vivifyPrograms absoluteIdentifiers, state
      # TODO: Also make working directory relative paths for readFile and writeFile

      context =
        system: localSystem
        global: global
        module: module
        exports: module.exports
        __filename: path
        __dirname: dirname

      args = Object.keys(context)
      values = args.map (name) -> context[name]

      Promise.resolve()
      .then ->
        Function(args..., program).apply(module, values)
      .catch reject

      # Scan for a module.exports to see if it is the kind of
      # module that exports things vs just plain side effects code
      # This can return false positives if it just matches the string and isn't
      # really exporting, regex is not a parser, yolo, etc.
      hasExports = program.match /module\.exports/

      # Just resolve next tick if we're not specifically exporting
      # can be fun with race conditions, but just export your biz, yo!
      if !hasExports
        setTimeout ->
          resolve(module)
        , 0

  # Wrap program in async include wrapper
  # Replaces references to require('something') with local variables in an async wrapper function
  rewriteRequires = (program) ->
    id = 0
    namePrefix = "__req"
    requires = {}

    # rewrite requires like `require('cool-module')` or `require('./relative-path')`
    # don't rewrite one that belong to another object `something.require('somepath')`
    # don't rewrite dynamic ones like `require(someVar)`
    rewrittenProgram = program.replace /[^.]require\(['"]([^'"]+)['"]\)/g, (match, key) ->
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
      return system.vivifyPrograms(#{JSON.stringify(requirePaths)})
      .then(function(__reqResults) {
      (function(#{tmpVars.join(', ')}){
      #{rewrittenProgram}
      }).apply(this, __reqResults);
      });
    """

  Object.assign self,
    autoboot: ->
      self.fs.list "/System/Boot/"
      .then (files) ->
        bootablePaths = files.filter ({blob}) ->
          blob?
        .map ({path}) ->
          path

        self.vivifyPrograms(bootablePaths)

    # May want to reconsider this name
    loadModule: (args...) ->
      self.Achievement.unlock "Execute code"
      loadModule(args...)

    # Execute in the context of the system itself
    spawn: (args...) ->
      loadModule(args...)
      .then ({exports}) ->
        if typeof exports is "function" and exports.length is 0
          result = exports()

          if result.element
            document.body.appendChild result.element

    execute: (absolutePath) ->
      self.vivifyPrograms [absolutePath]
      .then ([{exports}])->
        if typeof exports is "function" and exports.length is 0
          result = exports()

          if result.element
            document.body.appendChild result.element

    # still experimenting with the API
    # Async 'require' in the vein of require.js
    # it's horrible but seems necessary

    # This is an internal API and isn't recommended for general use
    # The state determines an include root and should be the same for a single
    # app or process
    vivifyPrograms: (absolutePaths, state={}) ->
      state.cache ?= {}

      Promise.all absolutePaths.map (absolutePath) ->
        state.cache[absolutePath] ?= self.loadProgram(absolutePath)
        .then (sourceProgram) ->
          # loadProgram returns an object in the case of JSON because it has no
          # dependencies and doesn't need an require re-writing
          # Having this special case lets us take a short cut without having to
          # Parse/unparse json extra.
          # This may be handy for other binary assets like images, etc. as well
          if typeof sourceProgram is "string"
            loadModule sourceProgram, absolutePath, state
          else
            exports: sourceProgram
        .then (module) ->
          module.exports

# Helpers
# -------

annotateSourceURL = (program, path) ->
  """
    #{program}
    //# sourceURL=#{path}
  """
