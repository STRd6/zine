###
Use the madness that is Amazon Cognito to support a 'My Briefcase' functionality.

This depends on having the AWS library available:
- https://sdk.amazonaws.com/js/aws-sdk-2.2.42.min.js

This is where you can put the files that you want to access from the cloud.

They'll live in the whimsy-fs bucket under the path to your aws user id.

The subdomain -> s3 proxy will have a map from simple names to the crazy ids.

The proxy will serve the /public folder in your 'briefcase'. You can put your
blog or apps or whatever there. The rest currently isn't 'private', but maybe
it should be. We can set the access control when uploading.

Ideally the briefcase will be browsable like the local FS and you'll be able to
run files from it, load them in applications, save files there, and drag n drop
between them.
###

Explorer = require "./explorer"
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

  system.Achievement.unlock "Oh no, my files!"

  LoginTemplate = system.compileTemplate """
    span(style="text-align: center; padding: 0 2em;")
      h1 My Briefcase
      p= @description
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
      unless e.message is "Invalid login token."
        console.warn e, e.message

  content LoginTemplate
    description: ->
      """
        Maintain access to your files across different machines. Publish
        effortlessly to the internet. Your briefcase holds all of your hopes
        and dreams in a magical cloud that is available anywhere there is an
        internet connection. 💼
      """
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

  windowView = Window
    title: "My Briefcase"
    width: 640
    height: 480
    content: content
    iconEmoji: "💼"

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
