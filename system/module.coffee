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
  htmlForPackage
  startsWith
  fetchDependency
} = require "../util"

Jadelet = require "../lib/jadelet.min"

module.exports = (I, self) ->
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


  Object.assign self,
    # A simpler, dumber, packager that reads a pixie.cson, then
    # packages every file recursively down in the directories
    createPackageFromPixie: (pixiePath) ->
      basePath = pixiePath.match(/^.*\//)?[0] or ""
      pkg =
        distribution: {}

      self.loadProgram(pixiePath).then (config) ->
        pkg.config = config
      .then ->
        self.readTree(basePath)
      .then (files) ->
        Promise.all files.map ({path, blob}) ->
          (if blob instanceof Blob
            self.compileFile(blob)
          else
            self.readFile(path)
            .then(self.compileFile)
          )
          .then (result) ->
            [path, result]
        .then (results) ->
          results.forEach ([path, result]) ->
            pkgPath = path.replace(basePath, "").replace(/\.[^.]*$/, "")

            if typeof result is "string"
              pkg.distribution[pkgPath] =
                content: result
            else
              console.warn "Can't package files like #{path} yet"

          return pkg

    # Load everything statically and put it in a package that can be run by our
    # `require`.
    packageProgram: (absolutePath, state={}) ->
      state.cache = {}
      state.pkg = {}

      basePath = absolutePath.match(/^.*\//)?[0] or ""
      state.basePath = basePath

      # Strip out base path and final suffix
      # NOTE: .coffee.md type files won't like this
      state.pkgPath = (path) ->
        path.replace(state.basePath, "").replace(/\.[^.]*$/, "")
      pkgPath = state.pkgPath(absolutePath)

      {pkg} = state
      pkg.distribution ?= {}

      unless state.loadConfigPromise
        configPath = absolutizePath basePath, "pixie.cson"
        state.loadConfigPromise = self.loadProgram(configPath).then (configSource) ->
          module = {}
          Function("module", configSource)(module)
          module.exports
        .then (config) ->
          entryPoint = config.entryPoint
          (if entryPoint
            path = absolutizePath(basePath, entryPoint)
            self.loadProgramIntoPackage(path, state)
          else
            Promise.resolve()
          ).then ->
            pkg.remoteDependencies = config.remoteDependencies
            pkg.config = config
        .catch (e) ->
          if e.message.match /File not found/i
            pkg.config = {}
          else
            throw e

      self.loadProgramIntoPackage(absolutePath, state)
      .then ->
        state.loadConfigPromise
      .then ->
        pkg.remoteDependencies = pkg.config.remoteDependencies
        if pkg.config.entryPoint
          pkg.entryPoint = pkg.config.entryPoint
        else
          pkg.entryPoint ?= pkgPath

        return pkg

    # Internal helper to load a program and its dependencies into the pkg
    # in the state
    # TODO: Loading deps like this doesn't work at all if require is used
    # from browserified js sources :(
    loadProgramIntoPackage: (absolutePath, state) ->
      {basePath, pkg} = state
      pkgPath = state.pkgPath(absolutePath)
      relativeRoot = absolutePath.replace(/\/[^/]*$/, "")

      state.cache[absolutePath] ?= self.loadProgram(absolutePath)
      .then (sourceProgram) ->
        if typeof sourceProgram is "string"
          # NOTE: Things will fail if we require ../../ above our
          # initial directory.
          # TODO: Detect and throw if requiring relative or absolute paths above
          # or outside of our base path

          # Add to package
          pkg.distribution[pkgPath] =
            content: sourceProgram
          pkg.dependencies ?= {}

          # Pull in dependencies
          depPaths = findDependencies(sourceProgram)

          Promise.all depPaths.map (depPath) ->
            Promise.resolve().then ->
              if isRelativePath depPath
                path = absolutizePath(relativeRoot, depPath)
                self.loadProgramIntoPackage path, state
              else if isAbsolutePath depPath
                throw new Error "Absolute paths not supported yet"
              else
                # package path
                if startsWith depPath, "!"
                  lookup = depPath
                else
                  lookup = pkg.config.dependencies[depPath]

                  if !lookup?
                    throw new Error "No dependency listed in `pixie.cson` for '#{depPath}'"

                fetchDependency(lookup)
                .then (depPkg) ->
                  pkg.dependencies[depPath] = depPkg
        else
          throw new Error "TODO: Can't package files like #{absolutePath} yet"



    loadProgram: (path, basePath="/") ->
      self.readForRequire path, basePath
      .then self.compileFile

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

    executeInIFrame: (absolutePath, inputFile) ->
      self.packageProgram(absolutePath)
      .then (pkg) ->
        self.executePackageInIFrame pkg, baseDirectory(absolutePath), inputFile

    # Execute a package in the context of an iframe
    # The package is converted into a blob url containing an html source that
    # will execute the package.
    executePackageInIFrame: (pkg, pwd="/", inputFile) ->
      html = system.htmlForPackage pkg
      blob = new Blob [html],
        type: "text/html; charset=utf-8"
      src = URL.createObjectURL blob

      data = Object.assign {}, pkg.config, {src: src}

      self.launchAppByAppData data,
        env:
          pwd: pwd
        inputFile: inputFile

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

    htmlForPackage: htmlForPackage

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
