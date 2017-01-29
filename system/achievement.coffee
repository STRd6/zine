Achievement = require "../lib/achievement"

{Observable} = UI = require "ui"

{emptyElement} = require "../util"

# TODO: Track unlocks, save/restore achievements
# TODO: Only display once
# TODO: View achievement progress grouped by area

achievementData = [{
  text: "Issue 1"
  icon: "📰"
  group: "Issue 1"
  description: "View Issue 1"
}, {
  text: "Cover-2-cover"
  icon: "📗"
  group: "Issue 1"
  description: "Read the entire issue"
}, {
  text: "Issue 2"
  icon: "📰"
  group: "Issue 2"
  description: "View Issue 2"
}, {
  text: "Lol wut"
  icon: "😂"
  group: "Issue 2"
  description: "Did you know Windows Vista had a magazine?"
}, {
  text: "Cover-2-cover 2: 2 cover 2 furious"
  icon: "📗"
  group: "Issue 2"
  description: "Read the entire issue"
}, {
  text: "Feeling the frog"
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
}, { # Social
  text: "Do you 'like' like me?"
  icon: "💕"
  group: "Social"
  description: "Have fine taste"
}]

restore = ->
  storedCheevos = []

  try
    storedCheevos = JSON.parse localStorage.cheevos

  storedAchieved = {}
  storedCheevos.forEach ({achieved, text}) ->
    storedAchieved[text] = achieved

  achievementData.forEach (cheevo) ->
    {text} = cheevo

    if storedAchieved[text]
      cheevo.achieved = true

persist = ->
  localStorage.cheevos = JSON.stringify(achievementData)

AchievementProgressPresenter = require "../presenters/achievement-group-progress"

groupBy = (xs, key) ->
  xs.reduce (rv, x) ->
    (rv[x[key]] ?= []).push(x)

    rv
  , {}

module.exports = (I, self) ->
  restore()

  Object.assign self,
    Achievement:
      groupData: Observable {}
      unlock: (name) ->
        opts = achievementData.find ({text}) ->
          text is name

        if opts and !opts.achieved
          opts.achieved = true

          persist()
          updateStatus()
          Achievement.display opts
      progressView: ->
        content = document.createElement "content"

        Observable ->
          data = self.Achievement.groupData()

          elements = Object.keys(data).map (group) ->
            AchievementProgressPresenter
              name: group
              achievements: data[group]

          emptyElement content
          elements.forEach (element) ->
            content.appendChild(element)

        return content

  updateStatus = ->
    self.Achievement.groupData groupBy(achievementData, "group")
  updateStatus()

  return self
