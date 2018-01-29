Explorer = require "../apps/explorer"
PkgFS = require "../lib/pkg-fs"

{
  name: "Explore"
  filter: (file) ->
    file.path.match(/💾$/) or
    file.path.match(/\.json$/)
  fn: (file) ->
    system.readFile(file.path)
    .then (blob) ->
      blob.readAsJSON()
    .then (pkg) ->
      mountPath = file.path + "/"
      fs = PkgFS(pkg, file.path)
      system.fs.mount mountPath, fs

      # TODO: Can we make the explorer less specialized here?
      element = Explorer
        path: mountPath
      windowView = system.UI.Window
        title: mountPath
        content: element
        menuBar: null
        width: 640
        height: 480
        iconEmoji: "📂"

      document.body.appendChild windowView.element
}
