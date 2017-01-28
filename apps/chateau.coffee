# Chat Based MUD

Drop = require "../lib/drop"
FileIO = require "../os/file-io"
Model = require "model"

Template = require "../templates/chateau"

sortBy = (attribute) ->
  (a, b) ->
    a[attribute] - b[attribute]

rand = (n) ->
  Math.floor(Math.random() * n)

createSocket = (room, accountId) ->
  new WebSocket("wss://message-relay.gomix.me/r/#{room}?accountId=#{accountId}")

setLocal = (data) ->
  localStorage.chateau = JSON.stringify(data)

getLocal = ->
  try
    JSON.parse localStorage.chateau

module.exports = ->
  # Global system
  {ContextMenu, MenuBar, Modal, Observable, Progress, Util:{parseMenu}, Window} = system.UI

  wordsArray = Observable []
  connected = Observable false

  avatars = {}
  myAccountId = null

  localData = getLocal()

  if localData
    myAccountId = localData.myAccountId
    avatars[myAccountId] = localData.myAvatar
  else
    myAccountId = "Anon" + Math.random().toString().substr(3)

  addAvatar = (accountId, url) ->
    avatars[accountId] =
      img: null
      color: "orange"
      x: rand canvas.width
      y: rand canvas.height

  updateWords = ->
    wordsElements = Object.keys(avatars).map (key) ->
      avatars[key]
    .filter ({say}) ->
      say
    .map ({x, y, say}) ->
      words = document.createElement "words"
      words.style.top = "#{y - 50}px"
      words.style.left = "#{x}px"
      words.innerText = say

      return words

    wordsArray wordsElements

  setAvatar = (blob) ->
    return unless myAvatar = avatars[myAccountId]

    Image.fromBlob(blob)
    .then (img) ->
      myAvatar.img = img

    blob.readAsDataURL()
    .then (url) ->
      myAvatar.dataURL = url

      broadcast
        avatar: url

  broadcast = (data) ->
    socket.send JSON.stringify
      type: "broadcast"
      message: data

  directMessage = (data, accountId) ->
    socket.send JSON.stringify
      type: "dm"
      recipient: accountId
      message: data

  updateNewcomer = (accountId) ->
    return unless myAvatar = avatars[myAccountId]

    data =
      move:
        x: myAvatar.x
        y: myAvatar.y
      avatar: myAvatar.dataURL
      say: myAvatar.say

    directMessage(data, accountId)

  canvas = document.createElement 'canvas'
  context = canvas.getContext('2d')

  canvas.onclick = (e) ->
    {pageX, pageY, currentTarget} = e
    {top, left} = currentTarget.getBoundingClientRect()

    x = pageX - left
    y = pageY - top

    broadcast
      move:
        x: x
        y: y

  content = Template
    canvas: canvas
    connected: connected
    words: wordsArray
    submit: (e) ->
      e.preventDefault()

      input = content.querySelector('input')
      words = input.value
      if words
        input.value = ""

        broadcast
          say: words

  Drop content, (e) ->
    files = e.dataTransfer.files

    if files.length
      file = files[0]

      setAvatar(file)

  socket = createSocket("cshopmilli", myAccountId)

  setInterval ->
    try
      socket.send JSON.stringify
        meta: "keepalive"
  , 30000

  socket.onopen = ->


  socket.onclose = ->
    connected false

  socket.onmessage = (e) ->
    message = JSON.parse e.data
    console.log message

    accountId = message.accountId

    switch message.type
      when "meta"
        if message.status is "connect"
          connected true
          myAccountId = accountId
      when "connect"
        # Add Avatar
        addAvatar(accountId)
        updateNewcomer(accountId)
      when "disconnect"
        # Remove Avatar
        delete avatars[accountId]
        updateWords()
      when "broadcast", "dm"
        {message} = message

        receiveMessage(message, accountId)

  receiveMessage = (message, accountId) ->
    avatars[accountId] ?=
      x: rand canvas.width
      y: rand canvas.height
      color: "orange"

    if message.move
      {x, y} = message.move
      avatars[accountId].x = x
      avatars[accountId].y = y

    if message.say
      avatars[accountId].say = message.say

    if message.avatar
      img = new Image()
      img.src = message.avatar

      avatars[accountId].img = img

    updateWords()

  AboutTemplate = system.compileTemplate """
    container
      h1 About
      p Chat with your friends in this online chateau!

      p Drag and drop an image to become your avatar.

      p Click to position yourself in the room.

      p Say what you want to talk with others!
  """

  handlers = Model().include(FileIO).extend
    exit: ->
      windowView.element.remove()

    about: ->
      Modal.show AboutTemplate()

  menuBar = MenuBar
    items: parseMenu """
      [F]ile
        E[x]it
      [H]elp
        [A]bout
    """
    handlers: handlers

  windowView = Window
    title: "Chateau"
    content: content
    menuBar: menuBar.element
    width: 640
    height: 480

  roomstate =
    background: null
    objects: []

  repaint = ->
    # Draw BG
    context.fillStyle = 'blue'
    context.fillRect(0, 0, canvas.width, canvas.height)

    {background, objects} = roomstate
    if background
      context.drawImage(background, 0, 0, canvas.width, canvas.height)

    # Draw Avatars/Objects
    Object.keys(avatars).map (accountId) ->
      avatars[accountId]
    .concat(objects).sort(sortBy("z")).forEach ({color, img, x, y}) ->
      if img
        {width, height} = img
        context.drawImage(img, x - width / 2, y - height / 2)
      else
        context.fillStyle = color
        context.fillRect(x - 25, y - 25, 50, 50)

    # Draw connection status
    if connected()
      indicatorColor = "green"
    else
      indicatorColor = "red"

    context.beginPath()
    context.arc(canvas.width - 20, 20, 10, 0, 2 * Math.PI, false)
    context.fillStyle = indicatorColor
    context.fill()
    context.lineWidth = 2
    context.strokeStyle = '#003300'
    context.stroke()

  resize = ->
    rect = canvas.getBoundingClientRect()
    canvas.width = rect.width
    canvas.height = rect.height

  windowView.on "resize", resize

  windowView.loadFile = handlers.loadFile

  animate = ->
    requestAnimationFrame animate
    repaint()

  animate()

  # TODO: ViewDidLoad? or equivalent event?
  setTimeout ->
    resize()

  return windowView
