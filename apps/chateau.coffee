IFrameApp = require "../lib/iframe-app"

module.exports = ->
  {Achievement} = system

  app = IFrameApp
    src: "https://danielx.net/chateau/"
    width: 960
    height: 540
    title: "Chateau"

  app.on "event", (name) ->
    switch name
      when "login"
        Achievement.unlock "Enter the Chateau"
      when "custom-avatar"
        Achievement.unlock "Puttin' on the Ritz"
      when "custom-background"
        Achievement.unlock "Paint the town red"
      when "file-upload"
        Achievement.unlock "It's in the cloud"

  return app
