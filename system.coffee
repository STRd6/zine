{fileSeparator, normalizePath} = require "./util"

# DexieDB Containing our FS
DexieFSDB = (dbName='fs') ->
  db = new Dexie dbName

  db.version(1).stores
  	files: 'path, blob, size, type, createdAt, updatedAt'

  return db

DexieFS = require "./lib/dexie-fs"
MountFS = require "./lib/mount-fs"

uniq = (array) ->
  Array.from new Set array

Ajax = require "ajax"
Model = require "model"
Achievement = require "./system/achievement"
Associations = require "./system/associations"
SystemModule = require "./system/module"
Template = require "./system/template"
UI = require "ui"

module.exports = (dbName='zine-os') ->
  self = Model()

  fs = MountFS()
  fs.mount "/", DexieFS(DexieFSDB(dbName))

  self.include(Achievement, Associations, SystemModule, Template)

  {title} = require "./pixie"
  [..., version] = title.split('-')

  self.extend
    ajax: Ajax()
    fs: fs

    version: -> version

    require: require
    stylus: require "./lib/stylus.min"

    moveFile: (oldPath, newPath) ->
      self.copyFile(oldPath, newPath)
      .then ->
        self.deleteFile(oldPath)

    copyFile: (oldPath, newPath) ->
      return Promise.resolve() if oldPath is newPath

      self.readFile(oldPath)
      .then (blob) ->
        self.writeFile(newPath, blob)

    moveFileSelection: (selectionData, destinationPath) ->
      Promise.resolve()
      .then ->
        {sourcePath, files} = selectionData
        if sourcePath is destinationPath
          return
        else
          Promise.all files.map ({relativePath}) ->
            self.moveFile("#{sourcePath}#{relativePath}", "#{destinationPath}#{relativePath}")

    readFile: (path, userEvent) ->
      if userEvent
        self.Achievement.unlock "Load a file"

      path = normalizePath "/#{path}"
      fs.read(path)

    readTree: (directoryPath) ->
      fs.list(directoryPath)
      .then (files) ->
        Promise.all files.map (file) ->
          if file.folder
            self.readTree(file.path)
          else
            file
      .then (filesAndFolderFiles) ->
        filesAndFolderFiles.reduce (a, b) ->
          a.concat(b)
        , []

    writeFile: (path, blob, userEvent) ->
      if userEvent
        self.Achievement.unlock "Save a file"

      path = normalizePath "/#{path}"
      fs.write path, blob

    deleteFile: (path) ->
      path = normalizePath "/#{path}"
      fs.delete(path)

    updateFile: (path, changes) ->
      path = normalizePath "/#{path}"
      fs.update(path, changes)

    urlForPath: (path) ->
      fs.read(path)
      .then URL.createObjectURL

    launchIssue: (date) ->
      require("./issues/#{date}")()

    # TODO: Move this into some kind of system utils
    installModulePrompt: ->
      UI.Modal.prompt("url", "https://danielx.net/editor/master.json")
      .then (url) ->
        throw new Error "No url given" unless url

        baseName = url.replace(/^https:\/\/(.*)/, "$1")
        .replace(/(\.json)?$/, "💾")

        pathPrompt = UI.Modal.prompt "path", "/lib/#{baseName}"
        .then (path) ->
          throw new Error "No path given" unless path
          path

        blobRequest = fetch url
        .then (result) ->
          result.blob()

        Promise.all([blobRequest, pathPrompt])
        .then ([path, blob]) ->
          self.writeFile(path, blob)

    installModule: (url, path) ->
      path ?= url.replace(/^https:\/\/(.*)/, "/lib/$1")
      .replace(/(\.json)?$/, "💾")

      fetch url
      .then (result) ->
        result.blob()
      .then (blob) ->
        self.writeFile(path, blob)

    # NOTE: These are experimental commands to run code
    execJS: (path) ->
      self.readFile(path)
      .then (file) ->
        file.readAsText()
      .then (programText) ->
        Function(programText)()

    Observable: UI.Observable
    UI: UI

    dumpModules: ->
      src = PACKAGE.source
      Object.keys(src).forEach (path) ->
        file = src[path]
        blob = new Blob [file.content]
        self.writeFile("System/#{path}", blob)

    dumpPackage: ->
      blob = new Blob [JSON.stringify(PACKAGE)], type: "application/json; charset=utf-8"
      self.writeFile("System 💾", blob)

  invokeBefore UI.Modal, "hide", ->
    self.Achievement.unlock "Dismiss modal"

  return self

invokeBefore = (receiver, method, fn) ->
  oldFn = receiver[method]

  receiver[method] = ->
    fn()
    oldFn.apply(receiver, arguments)
