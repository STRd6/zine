module.exports = ->
  {Achievement, iframeApp} = system

  app = iframeApp
    title: "Dungeon of Sadness"
    src: "https://danielx.net/ld33/"
    width: 648
    height: 507

  Achievement.unlock "The dungeon is in our heart"

  return app
