AchievementTemplate = require "../templates/achievement"

pending = []
displaying = false

module.exports = Achievement =
  display: (options={}) ->
    if displaying
      return pending.push(options)

    achievementElement = AchievementTemplate options
    document.body.appendChild achievementElement
    achievementElement.classList.add "display"

    displaying = true

    achievementElement.addEventListener "animationend", (e) ->
      achievementElement.remove()

      displaying = false
      if pending.length
        Achievement.display(pending.shift())

    , false

    return achievementElement
