FileIO = require "../os/file-io"
Model = require "model"

module.exports = () ->
  {ContextMenu, MenuBar, Modal, Observable, Progress, Table, Util:{parseMenu}, Window} = system.UI

  sourceData = [0...5].map (i) ->
    id: i
    name: "yolo"
    color: "#FF0000"

  headers = ["id", "name", "color"]

  models = sourceData.map (datum) ->
    Model(datum).attrObservable headers...

  InputTemplate = require "../templates/input"
  RowElement = (datum) ->
    tr = document.createElement "tr"
    types = [
      "number"
      "text"
      "color"
    ]
    
    console.log datum

    headers.forEach (key, i) ->
      td = document.createElement "td"
      td.appendChild InputTemplate 
        value: datum[key]
        type: types[i]

      tr.appendChild td

    return tr


  {element} = Table {
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
        # TODO: Re-render

    newFile: -> # TODO
    saveData: ->
      Promise.resolve new Blob [JSON.stringify(sourceData)],
        type: "application/json"

    about: ->
      Modal.alert "Spreadsheet v0.0.1 by Daniel X Moore"
    insertRow: ->
      # TODO: Data template
      sourceData.push
        id: 0
        name: "new"
        color: "#FF00FF"

      # TODO: Re-render
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

  return windowView
