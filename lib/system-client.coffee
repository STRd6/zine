Postmaster = require "postmaster"

do ->
  postmaster = Postmaster()

  applicationProxy = new Proxy {},
    get: (target, property, receiver) ->
      ->
        postmaster.invokeRemote "application", property, arguments...

  document.addEventListener "mousedown", ->
    applicationProxy.raiseToTop()

  # TODO: Can we auto-proxy these UI methods better?
  systemProxy = new Proxy
    UI:
      Modal:
        alert: ->
          window.alert arguments...
  ,
    get: (target, property, receiver) ->
      target[property] or
      ->
        postmaster.invokeRemote "system", property, arguments...

  # TODO: Also interesting would be to proxy observable arguments where we
  # create the receiver on the opposite end of the membrane and pass messages
  # back and forth like magic

  window.system = systemProxy
  window.application = applicationProxy
  window.postmaster = postmaster
