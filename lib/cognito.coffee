###
Cognito info:

JS SDK: https://github.com/aws/amazon-cognito-identity-js
Pricing: https://aws.amazon.com/cognito/pricing/
Adding Social Identity Providers: http://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-social.html

https://whimsy.auth.us-east-1.amazoncognito.com/oauth2/idpresponse
###

module.exports = ->
  identityPoolId = 'us-east-1:4fe22da5-bb5e-4a78-a260-74ae0a140bf9'

  poolData =
    UserPoolId : 'us-east-1_cfvrlBLXG'
    ClientId : '3fd84r6idec9iork4e9l43mp61'

  userPool = new AWSCognito.CognitoIdentityServiceProvider.CognitoUserPool(poolData)

  # Region needs to be set if not already set previously elsewhere.
  AWS.config.region = 'us-east-1'

  configureAWSFor = (session, resolve, reject) ->
    token = session.getIdToken().getJwtToken()

    AWS.config.credentials = new AWS.CognitoIdentityCredentials
      IdentityPoolId: identityPoolId
      Logins:
        'cognito-idp.us-east-1.amazonaws.com/us-east-1_cfvrlBLXG': token

    # refreshes credentials
    AWS.config.credentials.refresh (error) ->
      if error
        reject error
      else
        # TODO: AWS is global :(
        # Probably doesn't matter because ZineOS is single user
        resolve AWS

      return
    return

  mapAttributes = (attributes) ->
    return unless attributes

    Object.keys(attributes).map (name) ->
      value = attributes[name]

      new AWSCognito.CognitoIdentityServiceProvider.CognitoUserAttribute
        Name: name
        Value: value

  self =
    signUp: (username, password, attributes) ->
      attributeList = mapAttributes(attributes)
  
      new Promise (resolve, reject) ->
        userPool.signUp username, password, attributeList, null, (err, result) ->
          if err
            return reject(err)
  
          cognitoUser = result.user
          console.log('user name is ' + cognitoUser.getUsername())

          # User will need to confirm email address
          resolve cognitoUser

    authenticate: (username, password) ->
      authenticationData =
        Username : username
        Password : password
  
      authenticationDetails = new AWSCognito.CognitoIdentityServiceProvider.AuthenticationDetails(authenticationData)
  
      userData =
        Username : username
        Pool : userPool
  
      cognitoUser = new AWSCognito.CognitoIdentityServiceProvider.CognitoUser(userData)
  
      new Promise (resolve, reject) ->
        cognitoUser.authenticateUser authenticationDetails,
          onSuccess: (session) ->
            configureAWSFor session, resolve, reject
          onFailure: reject
  
    cachedUser: ->
      new Promise (resolve, reject) ->
        cognitoUser = userPool.getCurrentUser()
  
        if cognitoUser
          cognitoUser.getSession (err, session) ->
            if err
              reject err
              return
  
            configureAWSFor(session, resolve, reject)
        else
          reject new Error "No cached user"
  
    logout: ->
      Object.keys(localStorage).filter (key) ->
        key.match /^CognitoIdentityServiceProvider/
      .forEach (key) ->
        delete localStorage[key]
  
    # Redirect to FB Login URL
    fbAuth: ->
      fbAppId = "1259742007505134"
      # redirectURI = "https://whimsy.auth.us-east-1.amazoncognito.com/oauth2/idpresponse"
      redirectURI = "https://whimsy.space"
      scope = "public_profile,email"
      window.location = "https://www.facebook.com/v2.11/dialog/oauth?client_id=#{fbAppId}&redirect_uri=#{redirectURI}&scope=#{scope}"
  
      # This gets me back to the page with a code, but how do I use the code to get the Cognito User Pool user with it??????
