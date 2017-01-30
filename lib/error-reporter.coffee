window.addEventListener "error", (e) ->
  system.Achievement.unlock "I AM ERROR"

window.addEventListener "unhandledrejection", (e) ->
  system.Achievement.unlock "I AM ERROR"
