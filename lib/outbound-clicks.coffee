{parentElementOfType} = require "../util"

# Outbound clicker
document.addEventListener "click", (e) ->
  anchor = parentElementOfType("a", e.target)

  if anchor
    href = anchor.getAttribute('href')

    if href?.match /^http/
      e.preventDefault()

      if href.match /frogfeels\.com/
        system.Achievement.unlock "Feeling the frog"

      window.open href
