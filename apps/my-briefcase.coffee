###
Use the madness that is Amazon Cognito to support a 'My Briefcase' functionality.

This depends on having the AWS libraries available:
  https://danielx.whimsy.space/cdn/cognito/sdk.min.js
  https://danielx.whimsy.space/cdn/cognito/identity.min.js

This is where you can put the files that you want to access from the cloud.

They'll live in the whimsy-fs bucket under the path to your aws user id.

The subdomain -> s3 proxy will have a map from simple names to the crazy ids.

The proxy will serve the /public folder in your 'briefcase'. You can put your
blog or apps or whatever there. The rest is 'private' thanks to an AWS ACL on
the whimsy-fs bucket.

The briefcase is browsable like the local FS. You can run files from it, load
them in applications, save files there, and drag 'n' drop between them.

###

Cognito = require("../lib/cognito")()
Explorer = require "./explorer"
FileTemplate = require "../templates/file"
FolderTemplate = require "../templates/folder"
LoginTemplate = require "../templates/login"

S3FS = require "../lib/s3-fs"

{emptyElement, extensionFor, generalType, pinvoke, readTree} = require "../util"

module.exports = ->
  {Observable, Window} = system.UI

  system.Achievement.unlock "Oh no, my files!"

  LoadedTemplate = system.compileTemplate """
    section
      h1 Connected!
      p Loading files...
  """

  # Observable holding content element
  content = Observable null

  receivedCredentials = (AWS) ->
    console.log AWS.config.credentials
    id = AWS.config.credentials.identityId

    content LoadedTemplate()

    bucket = new AWS.S3
      params:
        Bucket: "whimsy-fs"

    refreshCredentials = ->
      # This has the side effect of updating the global AWS object's credentials
      Cognito.cachedUser()
      .then (AWS) ->
        # Copy the updated credentials to the bucket
        bucket.config.credentials = AWS.config.credentials

    fs = S3FS(id, bucket, refreshCredentials)

    bindAlgoliaIndex(id, fs)

    uuidToken = id.split(":")[1]

    system.fs.mount "/My Briefcase/", fs

    infoBlob = new Blob ["""
      Welcome to Your Cloud Briefcase
      ===============================

      Store your files in a magical cloud that floats between computers.

      Files stored in `My Briefcase/public` are available to anyone on the
      internet. (Technically so are all the files in your cloud briefcase...
      Security: Coming Soon™)

      But the ones in /public are easily accessible, like when computing was fun
      again. [Check this out](https://#{uuidToken}.whimsy.space/info.md)
      and see what I mean.

      You can get your own cool and non-ugly subdomain if you contact me (the
      creator of this computing system). Just send me your id and the short
      name you'd prefer. DM me in the friendsofjack slack or something.
    """] , type: "text/markdown; charset=utf-8"
    system.writeFile "/My Briefcase/public/info.md", infoBlob
    system.writeFile "/My Briefcase/public/.keep", new Blob []

    content Explorer
      path: "/My Briefcase/"

  loginModel =
    loading: Observable true
    state: Observable "start"
    submit: (e) ->
      e.preventDefault()
      @errorMessage ""

      if @state() is "register"
        @loading true

        if @password() is @confirmPassword()
          Cognito.signUp(@email(), @password())
          .then =>
            @loading false
            @errorMessage ""
            @state "confirm"
          .catch (e) =>
            @loading false
            @errorMessage "Error: " + e.message
        else
          @errorMessage "Error: Password does not match password confirmation"
          @loading false
      else
        @loading true

        Cognito.authenticate(@email(), @password())
        .then receivedCredentials
        .catch (e) =>
          @loading false

          @errorMessage "Error: " + e.message

    title: "💼 My Briefcase"
    description: """
      Maintain access to your files across different machines. Publish
      effortlessly to the internet. Your briefcase holds all of your hopes
      and dreams in a magical cloud that is available anywhere there is an
      internet connection.
    """
    email: Observable ""
    password: Observable ""
    confirmPassword: Observable ""
    errorMessage: Observable ""
  loginTemplate = LoginTemplate loginModel

  loginTemplate.style.width = "400px"

  content loginTemplate

  Cognito.cachedUser()
  .then receivedCredentials
  .catch ->
    loginModel.loading false

  windowView = Window
    title: "My Briefcase"
    width: 640
    height: 480
    content: content
    iconEmoji: "💼"

  return windowView

bindAlgoliaIndex = (id, fs) ->
  {ALGOLIA_SECRET} = localStorage
  unless ALGOLIA_SECRET
    console.warn "No Algolia key present, 'My Briefcase' will not be indexed."
    return

  console.log "Initializing Algolia indexing of 'My Briefcase'"

  client = algoliasearch("QM41V7R53B", ALGOLIA_SECRET)
  index = client.initIndex('My Briefcase')

  matchesContentType = (type) ->
    type.match /text|javascript/

  isPublic = (path) ->
    path.match /^\/public\//

  indexableContent = (blob) ->
    if matchesContentType(blob.type)
      blob.readAsText()
    else
      Promise.resolve()

  performIndex = (path, blob) ->
    return unless isPublic(path)

    console.log "Indexing:", path

    contentType = blob.type
    type = generalType(contentType)

    indexableContent(blob)
    .then (content) ->
      new Promise (resolve, reject) ->
        index.addObjects [{
          objectID: id + path
          path: path
          extension: extensionFor(path)
          content: content?.slice(0, 8192) # There's limits to the "full text" amount in the Algolia free tier. Records above 10k are rejected.
          contentType: contentType
          type: type
          size: blob.size
        }], (err, content) ->
          return reject(err) if err
          resolve(content)

  # TODO: Public URLs
  # TODO: Image metadata (width x height)

  fs.on "write", (path) ->
    # This taps into all writes, we should be able to trigger an Algolia
    # index action here
    console.log "Write: #{path}"
    fs.read(path).then (blob) ->
      performIndex(path, blob)

  # Remove index on delete
  fs.on "delete", (path) ->
    new Promise (resolve, reject) ->
      index.deleteObject id + path, (err) ->
        return reject(err) if err
        resolve()

  global.reindexBriefcase = ->
    readTree fs, "/public"
    .then (files) ->
      console.log "All Bfiles", files

      queue = files
      RETRY = {}

      processFile = (file) ->
        path = file.path

        fs.read(path)
        .then (blob) ->
          performIndex(path, blob)
        .catch (e) ->
          handleError e, file
        .then (result) ->
          if result is RETRY
            processFile(file)
          else
            return result

      handleError = (e, file) ->
        console.error e

        file.retries ?= 3
        if file.retries <= 0
          throw e
        else # retry
          file.retries -= 1
          return RETRY

      work = ->
        file = files.shift()

        if file
          processFile(file)
          .then ->
            work()

      work()
      work()
      work()
      work()

  return
