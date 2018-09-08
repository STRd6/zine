Achievement = require "./system/achievement"
Ajax = require "ajax"
Applications = require "./system/applications"
Bindable = require "bindable"
FS = require "./system/fs"
Mimes = require "./system/mimes"
Model = require "model"
SystemModule = require "./system/module"
Template = require "./system/template"
UI = require "ui"

module.exports = (I={}, self=Model(I)) ->
  I.dbName ?= 'zine-os'

  self.include Bindable, 
    FS, # Include FS before other modules
    Achievement,
    Applications,
    Mimes,
    require("./system/messaging"),
    SystemModule,
    Template

  {title} = require "./pixie"
  [..., version] = title.split('-')

  # Log system events
  self.on "*", console.log

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
