{pinvoke, startsWith, endsWith} = require "../util"

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

uploadToS3 = (bucket, key, file, options={}) ->
  {cacheControl} = options

  cacheControl ?= 0

  pinvoke bucket, "putObject",
    Key: key
    ContentType: file.type
    Body: file
    CacheControl: "max-age=#{cacheControl}"

# TODO: May need to use getObject api when we switch to better privacy model
getFromS3 = (bucket, key) ->
  fetch("https://#{bucket.config.params.Bucket}.s3.amazonaws.com/#{key}")
  .then status
  .then blob

deleteFromS3 = (bucket, key) ->
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
    console.log result

    results = result.CommonPrefixes.map (p) ->
      DirectoryEntry p.Prefix, id, prefix
    .concat result.Contents.map (o) ->
      FileEntry o, id, prefix
    .map (entry) ->
      fetchMeta(entry, bucket)

    Promise.all results

module.exports = (id, bucket) ->
  self =
    read: (path) ->
      unless startsWith path, delimiter
        path = delimiter + path

      key = "#{id}#{path}"

      getFromS3(bucket, key)

    write: (path, blob) ->
      unless startsWith path, delimiter
        path = delimiter + path

      key = "#{id}#{path}"

      uploadToS3 bucket, key, blob

    delete: (path) ->
      unless startsWith path, delimiter
        path = delimiter + path

      key = "#{id}#{path}"

      deleteFromS3 bucket, key

    list: (dir="/") ->
      list bucket, id, dir

fetchFileMeta = (fileEntry, bucket) ->
  pinvoke bucket, "headObject",
    Key: fileEntry.remotePath
  .then (result) ->
    fileEntry.type = result.ContentType

    fileEntry

fetchMeta = (entry, bucket) ->
  Promise.resolve()
  .then ->
    return entry if entry.directory

    fetchFileMeta entry, bucket

DirectoryEntry = (path, id, prefix) ->
  directory: true
  path: path.replace(id, "")
  relativePath: path.replace(prefix, "")
  remotePath: path

FileEntry = (object, id, prefix) ->
  path = object.Key

  path: path.replace(id, "")
  relativePath: path.replace(prefix, "")
  remotePath: path
  size: object.Size
