Bindable = require "bindable"
Model = require "model"

FolderEntry = (path, prefix) ->
  folder: true
  path: prefix + path
  relativePath: path

# Keys in the package's source object don't begin with slashes
sourcePath = (path) ->
  path.replace(/^\//, "")

# Strip out extension suffixes
distributionPath = (path) ->
  path.replace(/\..*$/, "")

# FS Wrapper to a pixie package
module.exports = (pkg, persistencePath) ->
  notify = (eventType, path) ->
    (result) ->
      self.trigger eventType, path
      return result

  persist = ->
    # Persist entire pkg
    pkgBlob = new Blob [JSON.stringify(pkg)],
      type: "application/json; charset=utf8"
    system.writeFile persistencePath, pkgBlob

  compileAndWrite = (path, blob) ->
    writeSource = blob.readAsText()
    .then (text) ->
      pkg.source[sourcePath(path)] =
        content: text
        type: blob.type

    # Compilers expect blob to be annotated with the path
    blob.path = path

    writeCompiled = system.compileFile(blob)
    .then (compiledSource) ->
      if typeof compiledSource is "string"
        pkg.distribution[distributionPath(sourcePath(path))] =
          content: compiledSource

    Promise.all [writeSource, writeCompiled]
    .then persist

  self = Model()
  .include(Bindable)
  .extend
    # Read a blob from a path
    read: (path) ->
      {content, type} = pkg.source[sourcePath(path)]

      blob = new Blob [content], type: type

      Promise.resolve blob
      .then notify "read", path

    # Write a blob to a path
    write: (path, blob) ->
      compileAndWrite(path, blob)
      .then notify "write", path

    # Delete a file at a path
    delete: (path) ->
      Promise.resolve()
      .then ->
        delete pkg.source[sourcePath(path)]
      .then notify "delete", path

    # List files and folders in a directory
    list: (dir) ->
      sourceDir = sourcePath(dir)

      Promise.resolve()
      .then ->
        Object.keys(pkg.source).filter (path) ->
          path.indexOf(sourceDir) is 0
        .map (path) ->
          path: "/" + path
          relativePath: path.replace(sourceDir, "")
          type: pkg.source[path].type
      .then (files) ->
        folderPaths = {}

        files = files.filter (file) ->
          if file.relativePath.match /\// # folder
            folderPath = file.relativePath.replace /\/.*$/, "/"
            folderPaths[folderPath] = true
            return
          else
            return file

        folders = Object.keys(folderPaths).map (folderPath) ->
          FolderEntry folderPath, dir

        return folders.concat(files)
