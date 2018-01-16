Bindable = require "bindable"
Model = require "model"

delimiter = "/"

status = (response) ->
  if response.status >= 200 && response.status < 300
    return response
  else
    throw response

json = (response) ->
  response.json()

blob = (response) ->
  response.blob()

module.exports = (id, bucket, refreshCredentials) ->
  {pinvoke, startsWith, endsWith} = require "../util"

  refreshCredentials ?= -> Promise.reject new Error "No method given to refresh credentials automatically"
  refreshCredentialsPromise = Promise.resolve()

  do (oldPromiseInvoke=pinvoke) ->
    pinvoke = (args...) ->
      # Guard for expired credentials
      refreshCredentialsPromise.then ->
        oldPromiseInvoke.apply(null, args)
      .catch (e) ->
        if e.code is "CredentialsError"
          console.info "Refreshing credentials after CredentialsError", e
          refreshCredentialsPromise = refreshCredentials()

          refreshCredentialsPromise.then ->
            # Retry calls after refreshing expired credentials
            oldPromiseInvoke.apply(null, args)
        else
          throw e

  localCache = {}

  uploadToS3 = (bucket, key, file, options={}) ->
    {cacheControl} = options
  
    cacheControl ?= 0
  
    # Optimistically Cache
    localCache[key] = file
  
    pinvoke bucket, "putObject",
      Key: key
      ContentType: file.type
      Body: file
      CacheControl: "max-age=#{cacheControl}"
  
  getRemote = (bucket, key) ->
    cachedItem = localCache[key]
  
    if cachedItem
      if cachedItem instanceof Blob
        return Promise.resolve(cachedItem)
      else
        return Promise.reject(cachedItem)
  
    pinvoke bucket, "getObject",
      Key: key
    .then (data) ->
      {Body, ContentType} = data
  
      new Blob [Body],
        type: ContentType
    .then (data) ->
      localCache[key] = data
    .catch (e) ->
      # Cache Not Founds too, since that's often what is slow
      localCache[key] = e
      throw e
  
  deleteFromS3 = (bucket, key) ->
    localCache[key] = new Error "Not Found"
  
    pinvoke bucket, "deleteObject",
      Key: key
  
  list = (bucket, id, dir) ->
    unless startsWith dir, delimiter
      dir = "#{delimiter}#{dir}"
  
    unless endsWith dir, delimiter
      dir = "#{dir}#{delimiter}"

    prefix = "#{id}#{dir}"

    pinvoke bucket, "listObjects",
      Prefix: prefix
      Delimiter: delimiter
    .then (result) ->
      results = result.CommonPrefixes.map (p) ->
        FolderEntry p.Prefix, id, prefix
      .concat result.Contents.map (o) ->
        FileEntry o, id, prefix, bucket
      .map (entry) ->
        fetchMeta(entry, bucket)

      Promise.all results

  fetchFileMeta = (fileEntry, bucket) ->
    pinvoke bucket, "headObject",
      Key: fileEntry.remotePath
    .then (result) ->
      fileEntry.type = result.ContentType
  
      fileEntry
  
  fetchMeta = (entry, bucket) ->
    Promise.resolve()
    .then ->
      return entry if entry.folder
  
      fetchFileMeta entry, bucket

  notify = (eventType, path) ->
    (result) ->
      self.trigger eventType, path
      return result

  FolderEntry = (path, id, prefix) ->
    folder: true
    path: path.replace(id, "")
    relativePath: path.replace(prefix, "")
    remotePath: path
  
  FileEntry = (object, id, prefix, bucket) ->
    path = object.Key
  
    entry =
      path: path.replace(id, "")
      relativePath: path.replace(prefix, "")
      remotePath: path
      size: object.Size
  
    entry.blob = BlobSham(entry, bucket)
  
    return entry

  BlobSham = (entry, bucket) ->
    remotePath = entry.remotePath

    getURL: ->
      getRemote(bucket, remotePath)
      .then URL.createObjectURL
    readAsText: ->
      getRemote(bucket, remotePath)
      .then (blob) ->
        blob.readAsText()

  self = Model()
  .include Bindable
  .extend
    read: (path) ->
      unless startsWith path, delimiter
        path = delimiter + path

      key = "#{id}#{path}"

      getRemote(bucket, key)
      .then notify "read", path

    write: (path, blob) ->
      unless startsWith path, delimiter
        path = delimiter + path

      key = "#{id}#{path}"

      uploadToS3 bucket, key, blob
      .then notify "write", path

    delete: (path) ->
      unless startsWith path, delimiter
        path = delimiter + path

      key = "#{id}#{path}"

      deleteFromS3 bucket, key
      .then notify "delete", path

    list: (folderPath="/") ->
      list bucket, id, folderPath
