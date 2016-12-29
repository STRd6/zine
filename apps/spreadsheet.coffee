module.exports = (os) ->
  {ContextMenu, MenuBar, Modal, Observable, Progress, Table, Util:{parseMenu}, Window} = os.UI
  
  # Observable input helper
  o = (value, type) ->
    attribute = Observable(value)
    if type
      attribute.type = type
  
    attribute.value = attribute
  
    return attribute

  data = Observable [0...5].map (i) ->
    id: o i
    name: o "yolo"
    color: o "#FF0000", "color"

  {element} = Table data

  menuBar = MenuBar
    items: parseMenu """
      Insert
        Row -> insertRow
      Help
        About
    """
    handlers:
      about: ->
        Modal.alert "Spreadsheet v0.0.1 by Daniel X Moore"
      insertRow: ->
        data.push
          id: o 50
          name: o "new"
          color: o "#FF00FF", "color"

  windowView = Window
    title: "MS Access 97 [DEMO VERSION]"
    content: element
    menuBar: menuBar.element
    width: 640
    height: 480

  return windowView
