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

  self.extend
    fs: fs

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

  invokeBefore UI.Modal, "hide", ->
    self.Achievement.unlock "Dismiss modal"

  return self

invokeBefore = (receiver, method, fn) ->
  oldFn = receiver[method]

  receiver[method] = ->
    fn()
    oldFn.apply(receiver, arguments)
