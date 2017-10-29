Model = require "model"

AchievementStatus = require "../apps/achievement-status"
MyBriefcase = require "../apps/my-briefcase"

StoryReader = require "../apps/story-reader"

Social = require "../social/social"

fetchContent = (targetFile, sourcePath=targetFile) ->
  targetPath = "/issue-7/#{targetFile}"

  system.readFile targetPath
  .then (file) ->
    throw new Error "File not found" unless file
  .catch ->
    system.ajax
      url: "https://danielx.whimsy.space/whimsy.space/V1E10/#{sourcePath}"
      responseType: "blob"
    .then (blob) ->
      system.writeFile targetPath, blob

module.exports = ->
  {ContextMenu, MenuBar, Modal, Progress, Util:{parseMenu}, Window} = system.UI
  {Achievement, ajax} = system

  system.Achievement.unlock "Issue 10"

  fetchContent "Todd Barranca.md"

  launch = (App) ->
    system.attachApplication App()

  handlers = Model().include(Social).extend
    area: ->
      "2017-10"

    bee: ->
      system.Achievement.unlock "Bee afraid"
      system.openPath "/issue-6/bee.md"

    toddBarranca: ->
      system.Achievement.unlock "Tree story"
      system.openPath "/issue-6/tree.md"

    achievementStatus: ->
      launch AchievementStatus

    myBriefcase: ->
      launch MyBriefcase

    pixiePaint: ->
      system.launchAppByName("Pixie Paint")

    codeEditor: ->
      system.launchAppByName("Code Editor")

    qfm: ->
      system.launchAppByName("Quest for Meaning")

  menuBar = MenuBar
    items: parseMenu """
      [A]pps
        My [B]riefcase
        [P]ixie Paint
        [C]ode Editor
      [G]ames
        [Q]uest for Meaning -> qfm
      [S]tories
        [T]odd Barranca
      #{Social.menuText}
      [H]elp
        [A]chievement Status
    """
    handlers: handlers

  iframe = document.createElement "iframe"
  iframe.src = "https://www.youtube.com/embed/WcCeyLf2IeE?autoplay=1&controls=0&showinfo=0&iv_load_policy=3"
  iframe.style = "width: 100%; height: 100%"

  windowView = Window
    title: "Whimsy.Space Volume 1 | Episode 10?? | Spoopin Right Now | October 2017"
    content: iframe
    iconEmoji: "🎃"
    menuBar: menuBar.element
    width: 536 + 8
    height: 357 + 46
    x: 64
    y: 64

  windowView.element.querySelector('viewport').style.overflow = "initial"

  document.body.appendChild windowView.element
