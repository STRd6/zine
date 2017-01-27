FileIO = require "../os/file-io"
Model = require "model"

module.exports = () ->
  {ContextMenu, MenuBar, Modal, Observable, Progress, Table, Util:{parseMenu}, Window} = system.UI

  system.Achievement.unlock "Microsoft Access 97"

  sourceData = []

  headers = ["id", "name", "color"]

  RowModel = (datum) ->
    Model(datum).attrObservable headers...

  models = sourceData.map RowModel

  InputTemplate = require "../templates/input"
  RowElement = (datum) ->
    tr = document.createElement "tr"
    types = [
      "number"
      "text"
      "color"
    ]

    headers.forEach (key, i) ->
      td = document.createElement "td"
      td.appendChild InputTemplate
        value: datum[key]
        type: types[i]

      tr.appendChild td

    return tr

  {element} = tableView = Table {
    data: models
    RowElement: RowElement
    headers: headers
  }

  handlers = Model().include(FileIO).extend
    loadFile: (blob) ->
      blob.readAsJSON()
      .then (json) ->
        console.log json

        unless Array.isArray json
          throw new Error "Data must be an array"

        sourceData = json
        # Update models data
        models.splice(0, models.length, sourceData.map(RowModel)...)

        # Re-render
        tableView.render()

    newFile: -> # TODO
    saveData: ->
      Promise.resolve new Blob [JSON.stringify(sourceData)],
        type: "application/json"

    about: ->
      Modal.alert "Spreadsheet v0.0.1 by Daniel X Moore"
    insertRow: ->
      # TODO: Data template
      datum =
        id: 0
        name: "new"
        color: "#FF00FF"

      sourceData.push datum
      models.push RowModel(datum)

      # Re-render
      tableView.render()
    exit: ->
      windowView.element.remove()

  menuBar = MenuBar
    items: parseMenu """
      [F]ile
        [N]ew
        [O]pen
        [S]ave
        Save [A]s
        -
        E[x]it
      Insert
        Row -> insertRow
      Help
        About
    """
    handlers: handlers

  windowView = Window
    title: "MS Access 97 [DEMO VERSION]"
    content: element
    menuBar: menuBar.element
    width: 640
    height: 480

  windowView.loadFile = handlers.loadFile

  return windowView
