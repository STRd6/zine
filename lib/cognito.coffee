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
    UserPoolId : 'us-east-1_XaxTbSC2i'
    ClientId : '6ooliggq05mdim27mkcsp649iu'

  userPool = new AWSCognito.CognitoIdentityServiceProvider.CognitoUserPool(poolData)

  mapAttributes = (attributes) ->
    return unless attributes

    Object.keys(attributes).map (name) ->
      value = attributes[name]

      new AWSCognito.CognitoIdentityServiceProvider.CognitoUserAttribute
        Name: name
        Value: value

  signUp: (username, password, attributes) ->
    attributeList = mapAttributes(attributes)

    new Promise (resolve, reject) ->
      userPool.signUp username, password, attributeList, null, (err, result) ->
        if err
          return reject(err)

        cognitoUser = result.user
        console.log('user name is ' + cognitoUser.getUsername())

        resolve(cognitoUser)

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
        onSuccess: (result) ->
          console.log('access token + ' + result.getAccessToken().getJwtToken())

          # Region needs to be set if not already set previously elsewhere.
          AWS.config.region = 'us-east-1'

          AWS.config.credentials = new AWS.CognitoIdentityCredentials
            IdentityPoolId: identityPoolId
            Logins:
              'cognito-idp.us-east-1.amazonaws.com/us-east-1_XaxTbSC2i': result.getIdToken().getJwtToken()

          # refreshes credentials using AWS.CognitoIdentity.getCredentialsForIdentity()
          AWS.config.credentials.refresh (error) ->
            if error
              return reject error
            else
              # Instantiate aws sdk service objects now that the credentials have been updated.

              console.log('Successfully logged!')

              # TODO: AWS is global :(
              # Probably doesn't matter because ZineOS is single user
              resolve AWS

        onFailure: reject

  # Redirect to FB Login URL
  fbAuth: ->
    fbAppId = "1259742007505134"
    # redirectURI = "https://whimsy.auth.us-east-1.amazoncognito.com/oauth2/idpresponse"
    redirectURI = "https://whimsy.space"
    scope = "public_profile,email"
    window.location = "https://www.facebook.com/v2.11/dialog/oauth?client_id=#{fbAppId}&redirect_uri=#{redirectURI}&scope=#{scope}"

    # This gets me back to the page with a code, but how do I use the code to get the Cognito User Pool user with it??????
