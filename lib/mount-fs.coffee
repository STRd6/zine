{startsWith} = require "../util"

Bindable = require "bindable"
Model = require "model"

module.exports = (I) ->
  mounts = {}
  mountPaths = []

  longestToShortest = (a, b) ->
    b.length - a.length

  findMountPathFor = (path) ->
    [mountPath] = mountPaths.filter (p) ->
      startsWith path, p

    return mountPath

  proxyToMount = (method) ->
    (path, params...) ->
      mountPath = findMountPathFor path

      if mountPath
        mount = mounts[mountPath]
      else
        throw new Error "No mounted filesystem for #{path}"

      subsystemPath = path.replace(mountPath, "/")

      if method is "list"
        # Remap paths when retrieving entries
        mount[method](subsystemPath, params...)
        .then (entries) ->
          entries.forEach (entry) ->
            entry.path = entry.path.replace("/", mountPath)

          return entries
      else if method is "read"
        mount[method](subsystemPath, params...)
        .then (blob) ->
          if blob
            blob.path = path

            return blob
      else
        mount[method](subsystemPath, params...)

  bindSubsystemEvents = (folderPath, subsystem) ->
    subsystem.on "*", (eventName, path) ->
      self.trigger eventName, path.replace("/", folderPath)

  self = Model()
  .include(Bindable)
  .extend
    read: proxyToMount "read"
    write: proxyToMount "write"
    delete: proxyToMount "delete"
    list: proxyToMount "list"

    mount: (folderPath, subsystem) ->
      mounts[folderPath] = subsystem
      mountPaths.push folderPath
      mountPaths.sort longestToShortest

      # Pass through all events
      bindSubsystemEvents(folderPath, subsystem)

      return self

  return self
