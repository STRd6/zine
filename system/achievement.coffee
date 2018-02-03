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
}, {
  text: "Blue light special"
  icon: "🈹"
  group: "Issue 3"
  description: "Read 'Blue Light Special'"
}, {
  text: "Issue 4"
  icon: "📰"
  group: "Issue 4"
  description: "View Issue 4"
}, {
  text: "Cover-2-cover 4: Fast & Furious"
  icon: "📗"
  group: "Issue 4"
  description: "Read the entire issue"
}, {
  text: "Izzy"
  icon: "🈹"
  group: "Issue 4"
  description: "Read 'Izzy'"
}, {
  text: "Residue"
  icon: "🈹"
  group: "Issue 4"
  description: "Read 'Residue'"
}, {
  text: "Issue 5"
  icon: "📰"
  group: "Issue 5"
  description: "View Issue 5"
}, {
  text: "Issue 6"
  icon: "🐝"
  group: "Issue 6"
  description: "View Issue 6"
}, {
  text: "Bee afraid"
  icon: "🐝"
  group: "Issue 6"
  description: "Learn the truth about 'Bee Movie'"
}, {
  text: "Tree story"
  icon: "🐝"
  group: "Issue 6"
  description: "Read Tree"
}, {
  text: "Issue 10"
  icon: "🎃"
  group: "Issue 10"
  description: "Special Halloween Editon"
}, {
  text: "Hard Rain"
  icon: "☔"
  group: "Issue 10"
  description: "Culvert Livin'"
}, {
  text: "3spoopy5me"
  icon: "😨"
  group: "Issue 10"
  description: "Don't spoop your pants!"
}, {
  text: "Not a real JT song"
  icon: "👻"
  group: "Issue 10"
  description: "Maybe he hired a ghost writer"
}, {
  text: "Issue 11"
  icon: "💃"
  group: "Issue 11"
  description: "You can dab if you wanna"
}, {
  text: "Late stage capitalism"
  icon: "💰"
  group: "Issue 11"
  description: "What if this is only the beginning?"
}, {
  text: "Value Investing"
  icon: "📈"
  group: "Issue 11"
  description: "Value investing has proven to be a successful investment strategy."
}, {
  text: "Getting Hairy"
  icon: "👣"
  group: "Issue 12"
  description: "Individuals claim to have seen Bigfoot."
}, {
  text: "As fortold in the Dead Sea Scrolls"
  icon: "📜"
  group: "V2E01"
  description: "Beyond revelations"
}, {
  text: "Inner or outer space?"
  icon: "🐬"
  group: "V2E01"
  description: "Out of this world"
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
}, {
  text: "Oh no, my files!"
  icon: "💼"
  group: "App"
  description: "Opened 'My Briefcase'"
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
}, {
  text: "Shut Down"
  icon: "🔌"
  group: "OS"
  description: "ZineOS cannot be stopped"
}, { # Social
  text: "Do you 'like' like me?"
  icon: "💕"
  group: "Social"
  description: "Have fine taste"
}, {
  text: "A little bird told me"
  icon: "🐦"
  group: "Social"
  description: "Social media marketing 101"
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
}, {
  text: "Rawr"
  icon: "🐉"
  group: "Contrasaurus"
  description: "Played Contrasaurus"
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
