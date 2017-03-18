###
Use the madness that is Amazon Cognito to support a 'My Briefcase' functionality.

This depends on having the AWS library available:
- https://sdk.amazonaws.com/js/aws-sdk-2.2.42.min.js

This is where you can put the files that you want to access from the cloud.

They'll live in the whims-fs bucket under the path to your aws user id.

The subdomain -> s3 proxy will have a map from simple names to the crazy ids.

The proxy will serve the /public folder in your 'briefcase'. You can put your
blog or apps or whatever there. The rest currently isn't 'private', but maybe
it should be. We can set the access control when uploading.

Ideally the briefcase will be browsable like the local FS and you'll be able to
run files from it, load them in applications, save files there, and drag n drop
between them.
###

FileTemplate = require "../templates/file"
FolderTemplate = require "../templates/folder"

S3FS = require "../lib/s3-fs"

{emptyElement, pinvoke} = require "../util"

window.onAmazonLoginReady = ->
  amazon.Login.setClientId('amzn1.application-oa2-client.29b275f9076a406c90a66b025fab96bf')

do (d=document) ->
  r = d.createElement 'div'
  r.id = "amazon-root"
  d.body.appendChild r
  a = d.createElement('script')
  a.type = 'text/javascript'
  a.async = true
  a.id = 'amazon-login-sdk'
  a.src = 'https://api-cdn.amazon.com/sdk/login1.js'
  r.appendChild(a)


module.exports = ->
  {Observable, Window} = system.UI

  LoginTemplate = system.compileTemplate """
    a#LoginWithAmazon(@click)
      img(border="0" alt="Login with Amazon" src="https://images-na.ssl-images-amazon.com/images/G/01/lwa/btnLWA_gold_156x32.png" width="156" height="32")
  """

  LoadedTemplate = system.compileTemplate """
    section
      h1 Connected!
      p Loading files...
  """

  # Observable holding content element
  content = Observable null

  receivedCredentials = ->
    console.log AWS.config.credentials
    id = AWS.config.credentials.identityId

    content LoadedTemplate()

    bucket = new AWS.S3
      params:
        Bucket: "whimsy-fs"

    fs = S3FS(id, bucket)
    fs.list()
    .then (files) -> 
      console.log files
      update files
      content explorer

  AWS.config.update
    region: 'us-east-1'

  try
    logins = JSON.parse localStorage.WHIMSY_FS_AWS_LOGIN

  AWS.config.credentials = new AWS.CognitoIdentityCredentials
    IdentityPoolId: 'us-east-1:4fe22da5-bb5e-4a78-a260-74ae0a140bf9'
    Logins: logins

  if logins
    pinvoke AWS.config.credentials, "get"
    .then receivedCredentials
    .catch (e) ->
      console.error e

  content LoginTemplate
    click: ->
      options = { scope : 'profile' }
      amazon.Login.authorize options, (resp) ->
        if !resp.error
          console.log resp
          token = resp.access_token
          creds = AWS.config.credentials
  
          logins =
            'www.amazon.com': token
          localStorage.WHIMSY_FS_AWS_LOGIN = JSON.stringify(logins)
  
          creds.params.Logins = logins
  
          creds.expired = true
  
          queryUserInfo(token)
  
          pinvoke AWS.config.credentials, "get"
          .then receivedCredentials

  # TODO: Reconcile this with the Explorer view
  explorer = document.createElement "explorer"
  update = (files) ->
    emptyElement explorer

    addedFolders = {}

    files.forEach (file) ->
      if file.relativePath.match /\// # folder
        folderPath = file.relativePath.replace /\/.*$/, ""
        addedFolders[folderPath] = true
        return

      file.dblclick = ->
        console.log "dblclick", file
        system.open file

      # file.contextmenu = (e) ->
      #   contextMenuFor(file, e)

      fileElement = FileTemplate file
      if file.type.match /^image\//
        file.blob.getURL()
        .then (url) ->
          icon = fileElement.querySelector('icon')
          icon.style.backgroundImage = "url(#{url})"
          icon.style.backgroundSize = "100%"
          icon.style.backgroundPosition = "50%"

      explorer.appendChild fileElement

    Object.keys(addedFolders).forEach (folderName) ->
      folder =
        # path: "#{path}#{folderName}/"
        relativePath: folderName
        contextmenu: (e) -> #contextMenuForFolder(folder, e)
        dblclick: ->
          # Open folder in new window
          ;# addWindow(folder.path)

      folderElement = FolderTemplate folder
      explorer.insertBefore(folderElement, explorer.firstChild)


  windowView = Window
    title: "My Briefcase"
    content: content
    width: 640
    height: 480

  return windowView

queryUserInfo = (token) ->
  fetch "https://api.amazon.com/user/profile",
    headers:
      Authorization: "bearer #{token}"
      Accept: "application/json"
  .then (response) ->
    response.json()
  .then (json) ->
    console.log json
  .catch (e) ->
    console.error e
