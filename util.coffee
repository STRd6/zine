fileSeparator = "/"

normalizePath = (path) ->
  path.replace(/\/+/g, fileSeparator) # /// -> /
  .replace(/\/[^/]*\/\.\./g, "") # /base/something/.. -> /base
  .replace(/\/\.\//g, fileSeparator) # /base/. -> /base

# NOTE: Allows paths like '../..' to go above the base path
absolutizePath = (base, relativePath) ->
  normalizePath "/#{base}/#{relativePath}"

makeScript = (src) ->
  "<script src=#{JSON.stringify(src)}><\/script>"

dependencyScripts = (remoteDependencies=[]) ->
  remoteDependencies.map(makeScript).join("\n")

metaTag = (name, content) ->
  "<meta name=#{JSON.stringify(name)} content=#{JSON.stringify(content)}>"

htmlForPackage = (pkg, opts={}) ->
  metas = [
    '<meta charset="utf-8">'
  ]

  {config, progenitor} = pkg
  config ?= {}

  {title, description} = config

  if title
    metas.push "<title>#{title}</title>"

  if description
    metas.push metaTag "description", description.replace("\n", " ")

  url = pkg.progenitor?.url
  if url
    metas.push "<link rel=\"Progenitor\" href=#{JSON.stringify(url)}>"

  code = """
    require('./#{pkg.entryPoint}');
  """

  """
    <!DOCTYPE html>
    <html>
      <head>
        #{metas.join("\n    ")}
        #{dependencyScripts(pkg.remoteDependencies)}
      </head>
      <body>
        <script>
          #{require.packageWrapper(pkg, code)}
        <\/script>
      </body>
    </html>
  """

startsWith = (str, prefix) ->
  str.lastIndexOf(prefix, 0) is 0

endsWith = (str, suffix) ->
  str.indexOf(suffix, str.length - suffix.length) != -1

extensionFor = (path) ->
  result = path.match /\.([^.]+)$/

  if result
    result[1]

readTree = (fs, directoryPath) ->
  fs.list(directoryPath)
  .then (files) ->
    Promise.all files.map (file) ->
      if file.folder
        readTree(fs, file.path)
      else
        file
  .then (filesAndFolderFiles) ->
    filesAndFolderFiles.reduce (a, b) ->
      a.concat(b)
    , []

ajax = require('ajax')()

MemoizePromise = (fn) ->
  cache = {}

  return (key) ->
    unless cache[key]
      cache[key] = fn.apply(this, arguments)

      # Remove cache and propagate error
      cache[key].catch (e) ->
        delete cache[key]
        throw e

    return cache[key]

###
If our string is an absolute URL then we assume that the server is CORS enabled
and we can make a cross origin request to collect the JSON data.

We also handle a Github repo dependency such as `STRd6/issues:master`.
This loads the package from the published gh-pages branch of the given repo.

`STRd6/issues:master` will be accessible at `http://strd6.github.io/issues/master.json`.
###

fetchDependency = MemoizePromise (path) ->
  if typeof path is "string"
    if startsWith(path, "!") # system package
      pkg = PACKAGE.dependencies[path]
      if pkg
        Promise.resolve pkg
      else
        Promise.reject new Error "No system package found for '#{path}'"
    else if startsWith(path, "http")
      ajax.getJSON(path)
      .catch ({status, response}) ->
        switch status
          when 0
            message = "Aborted"
          when 404
            message = "Not Found"
          else
            throw new Error response

        throw new Error "#{status} #{message}: #{path}"
    else
      if (match = path.match(/([^\/]*)\/([^\:]*)\:(.*)/))
        [callback, user, repo, branch] = match

        url = "https://#{user}.github.io/#{repo}/#{branch}.json"

        ajax.getJSON(url)
        .catch ->
          throw new Error "Failed to load package '#{path}' from #{url}"
      else
        Promise.reject new Error """
          Failed to parse repository info string #{path}, be sure it's in the
          form `<user>/<repo>:<ref>` for example: `STRd6/issues:master`
          or `STRd6/editor:v0.9.1`
        """
  else
    Promise.reject new Error "Can only handle url string dependencies right now, received: #{path}"


module.exports = Util =
  emptyElement: (element) ->
    while element.lastChild
      element.removeChild element.lastChild

  extensionFor: extensionFor

  fileSeparator: fileSeparator
  htmlForPackage: htmlForPackage
  normalizePath: normalizePath
  absolutizePath: absolutizePath

  fetchDependency: fetchDependency

  MemoizePromise: MemoizePromise

  # Execute a program with the given environment and context
  #
  # `program` is a string containing JavaScript code.
  # `context` is what is bound to `this` when executing the program.
  # `environment` is an object that binds its values to variables named by its
  # keys.
  execute: (program, context, environment) ->
    args = Object.keys(environment)
    values = args.map (name) -> environment[name]

    Function(args..., program).apply(context, values)

  isAbsolutePath: (path) ->
    path.match /^\//

  isRelativePath: (path) ->
    path.match /^.?.\//

  baseDirectory: (absolutePath="/") ->
    absolutePath.match(/^.*\//)?[0] or "/"

  parentElementOfType: (tagname, element) ->
    tagname = tagname.toLowerCase()

    if element.nodeName.toLowerCase() is tagname
      return element

    while element = element.parentNode
      if element.nodeName.toLowerCase() is tagname
        return element

  # Convert node style errbacks to promise style
  pinvoke: (object, method, params...) ->
    new Promise (resolve, reject) ->
      object[method] params..., (err, result) ->
        if err
          reject err
          return

        resolve result

  startsWith: startsWith

  endsWith: endsWith

  evalCSON: (coffeeSource) ->
    Promise.resolve()
    .then ->
      CoffeeScript.compile(coffeeSource, bare: true)
    .then (jsCode) ->
      # TODO: Security, lol
      Function("return " + jsCode)()

  generalType: (type="") ->
    type.replace(/^application\/|\/.*$/, "").replace(/;.*$/, "")

  readTree: readTree

  ###
  Get the first file from a drop event. Does nothing if the event has had
  defaultPrevented. Calls preventDefault if we handle the drop.

  We also handle the special case of dragging and dropping files from the system
  explorer.

  Returns a promise that is fulfilled with the file.
  ###
  fileFromDropEvent: (e) ->
    return if e.defaultPrevented

    fileSelectionData = e.dataTransfer.getData("zineos/file-selection")
    if fileSelectionData
      e.preventDefault()
      data = JSON.parse fileSelectionData

      selectedFile = data.files[0]
      return system.readFile(selectedFile.path)

    files = e.dataTransfer.files
    if files.length
      e.preventDefault()
      return Promise.resolve(files[0])

    return Promise.resolve()
