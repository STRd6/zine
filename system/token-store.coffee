module.exports = (I, self) ->
  # Persist tokens to a system file
  tokensFilePath = "System/tokens.json"

  tokenDataPromise =
    self.readFile(tokensFilePath)
    .then (file) ->
      if file
        file.readAsJSON()
      else
        {}

  self.extend
    setToken: (key, value) ->
      tokenDataPromise
      .then (tokenData) ->
        tokenData[key] = value
        blob = new Blob [JSON.stringify(tokenData)], 
          type: "application/json"
        self.writeFile(tokensFilePath, blob)

    getToken: (key) ->
      tokenDataPromise
      .then (tokenData) ->
        tokenData[key]
