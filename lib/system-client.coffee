# system-client is what prepares the environment for user apps
# we hook up the postmaster and proxy messages to the OS
# we also provide system packages for the application to use like UI

do ->
  # NOTE: These required packages get populated from the parent package when building
  # the runnable app. See util.coffee
  Postmaster = require "_SYS_postmaster"
  UI = require "_SYS_ui"

  style = document.createElement "style"
  style.innerHTML = UI.Style.all
  document.head.appendChild style

  postmaster = Postmaster()

  applicationProxy = new Proxy {},
    get: (target, property, receiver) ->
      ->
        postmaster.invokeRemote "application", property, arguments...

  document.addEventListener "mousedown", ->
    applicationProxy.raiseToTop()

  systemProxy = new Proxy
    Observable: UI.Observable
    UI: UI
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
