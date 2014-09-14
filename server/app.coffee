
http = require('http')
server = http.createServer()
io   = require('socket.io')(server)

server.listen(3132)
GAME_STATE = {}
userIds = 0


PLAYERS = []


class Player
  constructor : (@socket) ->
    @assignNewUser()
    @socket.on 'update:gamestate', @updateGamestate

  assignNewUser      : -> @socket.emit('assign-user', {userId : userIds++})
  broadcastGameState : -> io.emit('gamestate', GAME_STATE)
  updateGamestate    : (update) =>
    GAME_STATE[update.userId] ?= {value : 0}
    GAME_STATE[update.userId].value += update.valueInc ? 0
    @broadcastGameState()

io.on 'connection', (socket) => PLAYERS.push new Player(socket)