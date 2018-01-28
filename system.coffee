Ajax = require "ajax"
Model = require "model"
Achievement = require "./system/achievement"
Applications = require "./system/applications"
FS = require "./system/fs"
Mimes = require "./system/mimes"
SystemModule = require "./system/module"
Template = require "./system/template"
TokenStore = require "./system/token-store"
UI = require "ui"

module.exports = (I={}, self=Model(I)) ->
  I.dbName ?= 'zine-os'

  self.include FS, # Include FS first
    Achievement,
    Applications,
    Mimes,
    SystemModule,
    Template,
    TokenStore

  {title} = require "./pixie"
  [..., version] = title.split('-')

  self.extend
    ajax: Ajax()

    version: -> version

    require: require
    stylus: require "./lib/stylus.min"

    Observable: UI.Observable
    UI: UI

    launchIssue: (date) ->
      require("./issues/#{date}")()

  invokeBefore UI.Modal, "hide", ->
    self.Achievement.unlock "Dismiss modal"

  return self

invokeBefore = (receiver, method, fn) ->
  oldFn = receiver[method]

  receiver[method] = ->
    fn()
    oldFn.apply(receiver, arguments)
