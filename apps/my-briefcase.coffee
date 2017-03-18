###
Use the madness that is Amazon Cognito to support a 'My Briefcase' functionality.

This depends on having the AWS library available:
- https://sdk.amazonaws.com/js/aws-sdk-2.2.42.min.js
###

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
      h1 Loaded
      p TODO: Show yo files
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
  
    # TODO: Need to hook in to new FS
    # fs = require('./fs')(id, bucket)
    # os.attachFS fs

  AWS.config.update
    region: 'us-east-1'

  try
    logins = JSON.parse localStorage.WHIMSY_FS_AWS_LOGIN

  AWS.config.credentials = new AWS.CognitoIdentityCredentials
    IdentityPoolId: 'us-east-1:4fe22da5-bb5e-4a78-a260-74ae0a140bf9'
    Logins: logins

  -> # TODO: Load cached login
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

  windowView = Window
    title: "My Briefcase"
    content: content
    width: 640
    height: 480

  return windowView

pinvoke = (object, method, params...) ->
  new Promise (resolve, reject) ->
    object[method] params..., (err, result) ->
      if err
        reject err
        return

      resolve result

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
