Achievement = require "../lib/achievement"

# TODO: Track unlocks, save/restore achievements
# TODO: Only display once
# TODO: View achievement progress grouped by area

achievementData = [{
  text: "Issue 1"
  icon: "📰"
  group: "Issue"
  description: "View Issue 1"
}, {
  text: "Issue 2"
  icon: "📰"
  group: "Issue"
  description: "View Issue 2"
}, {
  text: "Lol wut"
  icon: "😂"
  group: "Issue 2"
  description: "Did you know Windows Vista had a magazine?"
}, {
  text: "Feel the frog"
  icon: "🐸"
  group: "Issue 2"
  description: "Visit frogfeels.com"
}, { # Apps
  text: "Notepad.exe"
  icon: "📝"
  group: "App"
  description: "Launch a text editor"
}, {
  text: "Pump up the jam"
  icon: "🎶"
  group: "App"
  description: "Launch audio application"
}, {
  text: "Microsoft Access 97"
  icon: "🔞"
  group: "App"
  description: "Launch a spreadsheet application"
}, {
  text: "Look at that"
  icon: "🖼️"
  group: "App"
  description: "Open the image viewer"
}, { # OS
  text: "Save a file"
  icon: "💾"
  group: "OS"
  description: "Write to the file system"
}, {
  text: "Load a file"
  icon: "💽"
  group: "OS"
  description: "Read from the file system"
}, {
  text: "Execute code"
  icon: "🖥️"
  group: "OS"
  description: "Some people like to live dangerously"
}, {
  text: "Dismiss modal"
  icon: "💃"
  group: "OS"
  description: "Dismiss a modal without even reading it"
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
