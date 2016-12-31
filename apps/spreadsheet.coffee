module.exports = (os) ->
  {ContextMenu, MenuBar, Modal, Observable, Progress, Table, Util:{parseMenu}, Window} = os.UI

  sourceData = [0...5].map (i) ->
    id: i
    name: "yolo"
    color: "#FF0000"

  {element} = Table {
    data
    RowElement: SampleRow
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
