AchievementTemplate = require "../templates/achievement"

pending = []
displaying = false

audioPath = "https://cdn.glitch.com/294e834f-223f-4792-9323-5b1fa8d0402b/unlock2.mp3"

playSound = ->
  audio = new Audio(audioPath)
  audio.autoplay = true

  audio

module.exports = Achievement =
  display: (options={}) ->
    if displaying
      return pending.push(options)

    options.title ?= "Achievement Unlocked"

    achievementElement = AchievementTemplate options
    document.body.appendChild achievementElement
    achievementElement.classList.add "display"
    achievementElement.appendChild playSound()

    displaying = true

    achievementElement.addEventListener "animationend", (e) ->
      achievementElement.remove()

      displaying = false
      if pending.length
        Achievement.display(pending.shift())

    , false

    return achievementElement
