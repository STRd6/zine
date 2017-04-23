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
  {script} = opts
  script ?= ""

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

  # Add postmaster dependency so package can talk with parent window
  pkg.dependencies ?= {}
  pkg.dependencies.postmaster ?= PACKAGE.dependencies.postmaster

  code = """
    #{script};
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

extensionFor = (path) ->
  result = path.match /\.([^.]+)$/

  if result
    result[1]

module.exports =
  emptyElement: (element) ->
    while element.lastChild
      element.removeChild element.lastChild

  extensionFor: extensionFor

  fileSeparator: fileSeparator
  htmlForPackage: htmlForPackage
  normalizePath: normalizePath
  absolutizePath: absolutizePath

  isAbsolutePath: (path) ->
    path.match /^\//

  isRelativePath: (path) ->
    path.match /^.?.\//

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

  startsWith: (str, prefix) ->
    str.lastIndexOf(prefix, 0) is 0

  endsWith: (str, suffix) ->
    str.indexOf(suffix, str.length - suffix.length) != -1

  evalCSON: (coffeeSource) ->
    Promise.resolve()
    .then ->
      CoffeeScript.compile(coffeeSource, bare: true)
    .then (jsCode) ->
      # TODO: Security, lol
      Function("return " + jsCode)()
