{endsWith, fileSeparator, normalizePath, readTree} = require "../util"

# DexieDB Containing our FS
DexieFSDB = (dbName='fs') ->
  db = new Dexie dbName

  db.version(1).stores
  	files: 'path, blob, size, type, createdAt, updatedAt'

  return db

DexieFS = require "../lib/dexie-fs"
MountFS = require "../lib/mount-fs"

module.exports = (I, self) ->
  {dbName} = I

  fs = MountFS()
  fs.mount "/", DexieFS(DexieFSDB(dbName))

  self.extend
    fs: fs

    moveFile: (oldPath, newPath) ->
      oldPath = normalizePath oldPath
      newPath = normalizePath newPath

      return Promise.resolve() if oldPath is newPath

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
            if relativePath.match(/\/$/)
              # Folder
              self.readTree("#{sourcePath}#{relativePath}")
              .then (files) ->
                Promise.all files.map (file) ->
                  targetPath = file.path.replace(sourcePath, destinationPath)
                  self.moveFile(file.path, targetPath)
            else
              self.moveFile("#{sourcePath}#{relativePath}", "#{destinationPath}#{relativePath}")

    readFile: (path, userEvent) ->
      if userEvent
        self.Achievement.unlock "Load a file"

      path = normalizePath "/#{path}"
      fs.read(path)
      .then (blob) ->
        throw new Error "File not found at #{path}" unless blob

        return blob

    readAsText: (path) ->
      self.readFile(path)
      .then (blob) ->
        if blob
          blob.readAsText()
        else
          throw new Error "File not found at '#{path}'"

    readTree: (directoryPath) ->
      readTree(fs, directoryPath)

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

  return self
