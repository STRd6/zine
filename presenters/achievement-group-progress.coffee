AchievementBadgeTemplate = require "../templates/achievement-badge"
ProgressTemplate = require "../templates/achievement-progress"

module.exports = ({name, achievements}) ->
  achieved = achievements.filter ({achieved}) ->
    achieved
  .length

  total = achievements.length
  value = achieved / total

  ProgressTemplate
    name: name
    achievements: achievements
    badges: achievements.map (cheevo) ->
      AchievementBadgeTemplate Object.assign {}, cheevo,
        class: ->
          "achieved" if cheevo.achieved
    fraction: "#{achieved}/#{total}"
    value: value.toString()
