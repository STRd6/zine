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
  text: "No rush"
  icon: "⏳"
  group: "Issue 1"
  description: "Patience is a virtue"
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
}, {
  text: "The dungeon is in our heart"
  icon: "😭"
  group: "Issue 2"
  description: "Played dungeon of sadness"
}, {
  text: "Issue 3"
  icon: "📰"
  group: "Issue 3"
  description: "View Issue 3"
}, {
  text: "Cover-2-cover 3: Tokyo Drift"
  icon: "📗"
  group: "Issue 3"
  description: "Read the entire issue"
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
}, {
  text: "Pixel perfect"
  icon: "◼️️"
  group: "App"
  description: "Open the pixel editor"
}, {
  text: "Check yo' self"
  icon: "😉"
  group: "App"
  description: "Check your achievement status"
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
}, {
  text: "I AM ERROR"
  icon: "🐛"
  group: "OS"
  description: "Encountered a JavaScript error"
}, { # Social
  text: "Do you 'like' like me?"
  icon: "💕"
  group: "Social"
  description: "Have fine taste"
}, {
  text: "We value your input"
  icon: "📩"
  group: "Social"
  description: "View feedback form"
}, { # Chateau
  text: "Enter the Chateau"
  icon: "🏡"
  group: "Chateau"
  description: "Enter the Chateau"
}, {
  text: "Puttin' on the Ritz"
  icon: "🐭"
  group: "Chateau"
  description: "Upload custom avatar"
}, {
  text: "Paint the town red"
  icon: "🌆"
  group: "Chateau"
  description: "Upload a custom background"
}, {
  text: "Poutine on the Ritz"
  icon: "🍘"
  group: "Chateau"
  description: "Put poutine on a Ritz cracker"
}, {
  text: "It's in the cloud"
  icon: "☁️️"
  group: "Chateau"
  description: "Upload a file"
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
