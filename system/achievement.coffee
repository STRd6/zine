Achievement = require "../lib/achievement"

# TODO: Track unlocks, save/restore achievements
# TODO: Only display once
# TODO: View achievement progress grouped by area

achievementData = [{
  text: "Issue 1"
  icon: "📰"
  group: "Issue"
}, {
  text: "Issue 2"
  icon: "📰"
  group: "Issue"
}, { # Apps
  text: "Feel the frog"
  icon: "🐸"
  group: "App"
}, {
  text: "Notepad.exe"
  icon: "📝"
  group: "App"
}, { # OS
  text: "Save a file"
  icon: "💾"
  group: "OS"
}, {
  text: "Load a file"
  icon: "💽"
  group: "OS"
}, {
  text: "Execute code"
  icon: "🖥️"
  group: "OS"
}]

module.exports = (I, self) ->
  Object.assign self,
    Achievement:
      unlock: (name) ->
        opts = achievementData.find ({text}) ->
          text is name

        if opts and !opts.achieved
          opts.achieved = true

          # TODO: Persist
          Achievement.display opts
