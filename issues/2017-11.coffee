Model = require "model"

AchievementStatus = require "../apps/achievement-status"
MyBriefcase = require "../apps/my-briefcase"

StoryReader = require "../apps/story-reader"

Social = require "../social/social"

fetchContent = (targetFile, sourcePath=targetFile) ->
  targetPath = "/issue-10/#{targetFile}"

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

  system.Achievement.unlock "Issue 11"

  launch = (App) ->
    system.attachApplication App()

  handlers = Model().include(Social).extend
    area: ->
      "2017-11"

    achievementStatus: ->
      launch AchievementStatus

    myBriefcase: ->
      launch MyBriefcase

  menuBar = MenuBar
    items: parseMenu """
      [G]ames
      [S]tories
      #{Social.menuText}
      [H]elp
        [A]chievement Status
    """
    handlers: handlers

  iframe = document.createElement "iframe"
  iframe.src = "https://www.youtube.com/embed/Mxstehc-YTk?autoplay=1&loop=1&controls=0&showinfo=0&playlist=Mxstehc-YTk&iv_load_policy=3"
  iframe.style = "width: 100%; height: 100%"

  windowView = Window
    title: "Whimsy.Space Volume 1 | Episode 11 | Do you dab? | November 2017"
    content: iframe
    iconEmoji: "💃"
    menuBar: menuBar.element
    width: 452
    height: 297
    x: 96
    y: 64

  windowView.element.querySelector('viewport').style.overflow = "initial"

  document.body.appendChild windowView.element
