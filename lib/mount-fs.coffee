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
      else
        mount[method](subsystemPath, params...)

  bindSubsystemEvent = (folderPath, subsystem, eventName) ->
    subsystem.on eventName, (path) ->
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

      # TODO: Want to be able to pass through all events
      bindSubsystemEvent(folderPath, subsystem, "write")
      bindSubsystemEvent(folderPath, subsystem, "update")
      bindSubsystemEvent(folderPath, subsystem, "delete")

      return self

  return self
