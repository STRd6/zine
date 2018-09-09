# Handles loading and launching files from the fs
#
# Depends on having self.readFile defined

{
  absolutizePath
  baseDirectory
  evalCSON
  fileSeparator
  normalizePath
  isAbsolutePath
  isRelativePath
  startsWith
  fetchDependency
} = require "../util"

Jadelet = require "../lib/jadelet.min"

module.exports = (I, self) ->
  findDependencies = (sourceProgram) ->
    requireMatcher = /(^|[^.])require\(['"]([^'"]+)['"]\)/g
    results = []
    count = 0

    loop
      match = requireMatcher.exec sourceProgram

      if match
        results.push match[2]
      else
        break

      # Circuit breaker for safety
      count += 1
      if count > 256
        break

    return results

  Object.assign self,
    findDependencies: findDependencies

    # Load everything statically and put it in a package that can be run by our
    # `require`.
    packageProgram: (absolutePath) ->
      state =
        cache: {}
        pkg:
          config: {}
          distribution: {}
          dependencies: # Pre-load system client dependency
            "!system": PACKAGE.dependencies["!system"]
          source: {}

      {pkg} = state

      basePath = absolutePath.match(/^.*\//)?[0] or ""
      state.basePath = basePath

      # Strip out base path and final suffix
      # NOTE: .coffee.md type files won't like this
      state.pkgPath = (path) ->
        path.replace(state.basePath, "").replace(/\.[^.]*$/, "")
      pkgPath = state.pkgPath(absolutePath)

      # Load Config
      configPath = absolutizePath basePath, "pixie.cson"
      self.loadProgramIntoPackage(configPath, state)
      .catch (e) ->
        throw e unless e.message.match /File not found/i
      .then -> # Apply config
        if pkg.distribution.pixie
          # Remove 'module.exports = ' and parse as JSON
          config = JSON.parse pkg.distribution.pixie.content.slice(17)

          pkg.entryPoint = config.entryPoint
          pkg.remoteDependencies = config.remoteDependencies
          pkg.config = config
      .then -> # Load Entry point
        # Load the entry point defined in pixie.cson if present
        if entryPoint = pkg.entryPoint
          path = absolutizePath(basePath, entryPoint)
          self.loadProgramIntoPackage(path, state)
      .then -> # Load program
        self.loadProgramIntoPackage(absolutePath, state)
      .then ->
        # Override entry point from package config
        # we're packaging so we can run with the given file.
        if pkgPath != "pixie"
          pkg.entryPoint = pkgPath

        return pkg

    # Internal helper to load a program and its dependencies into the pkg
    # in the state
    # TODO: Loading deps like this doesn't work at all if require is used
    # from browserified js sources :(
    loadProgramIntoPackage: (absolutePath, state) ->
      {basePath, pkg} = state
      pkgPath = state.pkgPath(absolutePath)
      relativeRoot = absolutePath.replace(/\/[^/]*$/, "")

      # TODO: Separate the resolving from the compiling
      state.cache[absolutePath] ?= self.loadProgram(absolutePath)
      .then ([compiledProgram, file, source]) ->
        pkg.source[file.path.replace(state.basePath, "")] =
          content: source
          type: file.type

        if typeof compiledProgram is "string"
          # NOTE: Things will fail if we require ../../ above our
          # initial directory.
          # TODO: Detect and throw if requiring relative or absolute paths above
          # or outside of our base path

          # Add to package
          pkg.distribution[pkgPath] =
            content: compiledProgram

          # Pull in dependencies
          depPaths = findDependencies(compiledProgram)

          Promise.all depPaths.map (depPath) ->
            Promise.resolve()
            .then ->
              if isRelativePath depPath
                path = absolutizePath(relativeRoot, depPath)
                self.loadProgramIntoPackage path, state
              else if isAbsolutePath depPath
                throw new Error "Absolute paths not supported yet"
              else # package path
                if startsWith depPath, "!" # special system package
                  pkg.dependencies[depPath] = PACKAGE.dependencies[depPath]
                else
                  lookup = pkg.config.dependencies[depPath]

                  if !lookup?
                    throw new Error "No dependency listed in `pixie.cson` for '#{depPath}'"

                  fetchDependency(lookup)
                  .then (depPkg) ->
                    pkg.dependencies[depPath] = depPkg
        else
          throw new Error "TODO: Can't package files like #{absolutePath} yet"

    # Handle requiring with or without explicit extension
    #     require "a"
    # First check:
    #     a
    #     a.coffee
    #     a.coffee.md
    #     a.litcoffee
    #     a.jadelet
    #     a.js
    loadProgram: (path, basePath="/") ->
      absolutePath = absolutizePath(basePath, path)

      suffixes = [
        ""
        ".coffee"
        ".coffee.md"
        ".litcoffee"
        ".jadelet"
        ".js"
        ".styl"
      ]

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

      # TODO: Clean up compilers and this double reading source stuff :*(
      .then (file) ->
        self.compileFile file
        .then (compiled) ->
          file.readAsText().then (source) ->
            [compiled, file, source]

    compileFile: (file) ->
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

    evalCSON: evalCSON

    compileStylus: (source) ->
      self.stylus(source).render()

    compileCoffee: (source, options={}) ->
      options.bare ?= true

      CoffeeScript.compile source, options

# Compile files based on type to JS program source
# These compilers return a string of JS source code that assigns a
# result to module.exports
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
      Jadelet.compile jadeletSource,
        compiler: CoffeeScript
        mode: "jade"
        runtime: "require('!jadelet')"
}, {
  filter: ({path}) ->
    path.match /\.styl$/
  fn: (blob) ->
    blob.readAsText()
    .then (source) ->
      system.stylus(source).render()
    .then stringifyExport
}, {
  filter: ({path}) ->
    path.match /\.json$/
  fn: (blob) ->
    blob.readAsJSON()
    .then stringifyExport
}, {
  filter: ({path}) ->
    path.match /\.cson$/
  fn: (blob) ->
    blob.readAsText()
    .then evalCSON
    .then stringifyExport
}, {
  filter: ({path}) ->
    path.match /\.te?xt$/
  fn: (blob) ->
    blob.readAsText()
    .then stringifyExport
}]

stringifyExport = (data) ->
  "module.exports = #{JSON.stringify(data)}"
