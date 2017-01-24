Achievement = require "../lib/achievement"

# TODO: Track unlocks, save/restore achievements
# TODO: Only display once
# TODO: View achievement progress grouped by area

module.exports = (I, self) ->
  Object.assign self,
    achieve: (opts) ->
      Achievement.display opts
