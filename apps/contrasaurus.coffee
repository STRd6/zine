module.exports = ->
  {Achievement, iframeApp} = system

  app = iframeApp
    src: "https://contrasaur.us/"
    width: 960
    height: 540
    title: "Contrasaurus: Defender of the American Dream"

  Achievement.unlock "Rawr"

  app.on "event", (name) ->
    switch name
      when "win"
        Achievement.unlock "A winner is you"

  return app
