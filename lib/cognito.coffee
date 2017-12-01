module.exports = ->
  poolData =
    UserPoolId : 'us-east-1_XaxTbSC2i'
    ClientId : '6ooliggq05mdim27mkcsp649iu'

  userPool = new AWSCognito.CognitoIdentityServiceProvider.CognitoUserPool(poolData)

  mapAttributes = (attributes) ->
    Object.keys(attributes).map (name) ->
      value = attributes[name]

      new AWSCognito.CognitoIdentityServiceProvider.CognitoUserAttribute
        Name: name
        Value: value

  signUp: (username, password, attributes) ->
    attributeList = mapAttributes(attributes)

    userPool.signUp username, password, attributeList, null, (err, result) ->
      if err
        throw err
      cognitoUser = result.user;
      console.log('user name is ' + cognitoUser.getUsername())
