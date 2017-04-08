# Handles loading and launching files from the fs
#
# Depends on having self.readFile defined

IFrameApp = require "../lib/iframe-app"

module.exports = (I, self) ->
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

  {absolutizePath, fileSeparator, normalizePath, isAbsolutePath, isRelativePath} = require "../util"

  findDependencies = (sourceProgram) ->
    requireMatcher = /[^.]require\(['"]([^'"]+)['"]\)/g
    results = []
    count = 0

    loop
      match = requireMatcher.exec sourceProgram

      if match
        results.push match[1]
      else
        break

      # Circuit breaker for safety
      count += 1
      if count > 256
        break

    return results

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

  Object.assign self,
    autoboot: ->
      self.fs.list "/System/Boot"
      .then (files) ->
        bootablePaths = files.filter ({blob}) ->
          blob?
        .map ({path}) ->
          path

        self.vivifyPrograms(bootablePaths)

    # This is kind of the opposite approach of the vivifyPrograms, here we want 
    # to load everything statically and put it in a package that can be run by
    # `require`.
    packageProgram: (absolutePath, state={}) ->
      state.cache ?= {}
      state.pkg ?= {}

      fileBasePath = absolutePath.match(/^.*\//)?[0] or ""
      state.basePath ?= fileBasePath

      {pkg} = state
      pkg.distribution ?= {}

      state.cache[absolutePath] ?= self.loadProgram(absolutePath)
      .then (sourceProgram) ->
        if typeof sourceProgram is "string"
          # NOTE: Things will fail if we require ../../ above our
          # initial directory.
          # TODO: Detect and throw if requiring relative or absolute paths above
          # or outside of our base path

          # Strip out base path and final suffix
          # NOTE: .coffee.md type files won't like this
          pkgPath = absolutePath.replace(state.basePath, "").replace(/\.[^.]*$/, "")
          # Add to package
          pkg.entryPoint ?= pkgPath
          pkg.distribution[pkgPath] =
            content: sourceProgram

          # Pull in dependencies
          depPaths = findDependencies(sourceProgram)
          Promise.all depPaths.map (depPath) ->
            Promise.resolve().then ->
              if isRelativePath depPath
                path = absolutizePath(fileBasePath, depPath)
                self.packageProgram path, state
              else if isAbsolutePath depPath
                throw new Error "Absolute paths not supported yet"
              else
                # package path
                depPkg = PACKAGE.dependencies[depPath]
                if depPkg
                  pkg.dependencies ?= {}
                  pkg.dependencies[depPath] = depPkg
                else
                  # TODO: Load from remote?
                  throw new Error "Package '#{depPath}' not found"
          .then ->
            return pkg
        else
          throw new Error "TODO: Can't package files like #{absolutePath} yet"

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

    loadProgram: (path, basePath="/") ->
      self.readForRequire path, basePath
      .then (file) ->
        # system modules are loaded as functions/objects right now, so just return them
        unless file instanceof Blob
          return file

        [compiler] = compilers.filter ({filter}) ->
          filter file

        if compiler
          compiler.fn(file)
        else
          # Return the blob itself if we didn't find any compilers
          return file

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

    executeInIFrame: (absolutePath) ->
      self.packageProgram(absolutePath)
      .then (pkg) ->
        self.executePackageInIFrame pkg

    # Execute a package in the context of an iframe
    executePackageInIFrame: (pkg) ->
      app = IFrameApp
        pkg: pkg

      document.body.appendChild app.element

      return app

    # Handle requiring with or without explicit extension
    #     require "a"
    # First check:
    #     a
    #     a.coffee
    #     a.coffee.md
    #     a.litcoffee
    #     a.jadelet
    #     a.js
    readForRequire: (path, basePath) ->
      # Hack to load 'system' modules
      isModule = !path.match(/^.?.?\//)
      if isModule
        return Promise.resolve()
        .then ->
          require path

      absolutePath = absolutizePath(basePath, path)

      suffixes = ["", ".coffee", ".coffee.md", ".litcoffee", ".jadelet", ".js", ".styl"]

      p = suffixes.reduce (promise, suffix) ->
        promise.then (file) ->
          return file if file
          filePath = "#{absolutePath}#{suffix}"
          self.readFile(filePath)
          .catch -> # If read fails try next read
      , Promise.resolve()

      p.then (file) ->
        unless file
          tries = suffixes.map (suffix) ->
            "#{absolutePath}#{suffix}"
          throw new Error "File not found at path: #{absolutePath}. Tried #{tries}"

        return file

# Compile files based on type to JS program source
compilers = [{
  filter: ({path}) ->
    path.match /\.js$/
  fn: (blob) ->
    blob.readAsText()
}, {
  filter: ({path}) ->
    path.match(/\.coffee.md$/) or
    path.match(/\.litcoffee$/)
  fn: (blob) ->
    blob.readAsText()
    .then (coffeeSource) ->
      CoffeeScript.compile coffeeSource, bare: true, literate: true
}, {
  filter: ({path}) ->
    path.match /\.coffee$/
  fn: (blob) ->
    blob.readAsText()
    .then (coffeeSource) ->
      CoffeeScript.compile coffeeSource, bare: true
}, {
  filter: ({path}) ->
    path.match /\.jadelet$/
  fn: (blob) ->
    blob.readAsText()
    .then (jadeletSource) ->
      Hamlet.compile jadeletSource,
        compiler: CoffeeScript
        mode: "jade"
        runtime: "require('_lib_hamlet-runtime')"
}, {
  filter: ({path}) ->
    path.match /\.styl$/
  fn: (blob) ->
    blob.readAsText()
    .then (source) ->
      cssString = system.stylus(source).render()

      "module.exports = #{JSON.stringify(cssString)}"
}, {
  filter: ({path}) ->
    path.match /\.json$/
  fn: (blob) ->
    blob.readAsJSON()
}, {
  filter: ({path}) ->
    path.match /\.cson$/
  fn: (blob) ->
    blob.readAsText()
    .then (coffeeSource) ->
      "module.exports = #{CoffeeScript.compile(source, bare: true)}"
}, {
  filter: ({path}) ->
    path.match /\.te?xt$/
  fn: (blob) ->
    blob.readAsText()
    .then (txt) ->
      "module.exports = #{JSON.stringify(txt)}"
}]

annotateSourceURL = (program, path) ->
  """
    #{program}
    //# sourceURL=#{path}
  """
