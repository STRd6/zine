Bindable = require "bindable"
Model = require "model"

# FS Wrapper to Dexie database
module.exports = (db) ->
  Files = db.files

  notify = (eventType, path) ->
    (result) ->
      self.trigger eventType, path
      return result

  self = Model()
  .include(Bindable)
  .extend
    # Read a blob from a path
    read: (path) ->
      Files.get(path)
      .then ({blob}) ->
        blob
      .then notify "read", path

    # Write a blob to a path
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

    # Delete a file at a path
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
