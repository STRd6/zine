# DexieDB Containing our FS
DexieFSDB = (dbName='fs') ->
  db = new Dexie dbName

  db.version(1).stores
  	files: 'path, blob, size, type, createdAt, updatedAt'

  return db

# FS Wrapper to DB
DexieFS = (db) ->
  Files = db.files

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

  delete: (path) ->
    Files.delete(path)

  list: (dir) ->
    Files.where("path").startsWith(dir).toArray()
    .then (results) ->
      uniq results.map ({path}) ->
        path = path.replace(dir, "").replace(/\/.*$/, "/")

uniq = (array) ->
  Array.from new Set array

readAsText = (file) ->
  new Promise (resolve, reject) ->
    reader = new FileReader
    reader.onload = ->
      resolve reader.result
    reader.onerror = reject
    reader.readAsText(file)

UI = require "ui"

module.exports = (dbName='zine-os') ->
  self = {}

  fs = DexieFS(DexieFSDB(dbName))

  Object.assign self, fs

  self.readAsText = (path) ->
    fs.read(path)
    .then ({blob}) ->
      readAsText blob

  self.UI = UI

  return self
