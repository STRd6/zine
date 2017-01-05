{fileSeparator, normalizePath} = require "./util"

# DexieDB Containing our FS
DexieFSDB = (dbName='fs') ->
  db = new Dexie dbName

  db.version(1).stores
  	files: 'path, blob, size, type, createdAt, updatedAt'

  return db

# FS Wrapper to DB
DexieFS = (db) ->
  Files = db.files

  notify = (eventType, path) ->
    (result) ->
      self.trigger eventType, path
      return result

  self = Model()
  .include(Bindable)
  .extend
    read: (path) ->
      Files.get(path)

    write: (path, blob) ->
      now = +new Date

      Files.put
        path: path
        blob: blob
        size: blob.size
        type: blob.type
        createdAt: now
        updatedAt: now
      .then notify "write", path

    delete: (path) ->
      Files.delete(path)
      .then notify "delete", path

    # TODO: Collapse folders
    # .replace(/\/.*$/, "/")
    list: (dir) ->
      Files.where("path").startsWith(dir).toArray()
      .then (files) ->
        files.forEach (file) ->
          file.relativePath = file.path.replace(dir, "")
  
        return files

uniq = (array) ->
  Array.from new Set array

Bindable = require "bindable"
Model = require "model"
SystemModule = require "./system/module"
UI = require "ui"

module.exports = (dbName='zine-os') ->
  self = Model()

  fs = DexieFS(DexieFSDB(dbName))

  self.include(SystemModule)

  self.extend
    fs: fs

    # TODO: Allow relative paths
    readFile: (path) ->
      path = normalizePath "/#{path}"

      fs.read(path)
      .then ({blob}) ->
        blob

    # TODO: Allow relative paths
    writeFile: (path, blob) ->
      path = normalizePath "/#{path}"

      fs.write path, blob

    # NOTE: These are experimental commands to run code
    execJS: (path) ->
      self.readFile(path)
      .then (file) ->
        file.readAsText()
      .then (programText) ->
        Function(programText)()

    UI: UI

  return self
