---
---

socket = io('http://localhost:3132')

USER = {
  userId : -1
}

startUpdateLoop = ->
  setInterval(->
    socket.emit('update:gamestate', {
      userId   : USER.userId
      valueInc : 1
    });
  , 1000)

socket.on 'assign-user', (userData) ->
  console.log 'assigned'
  _.extend(USER, userData)
  startUpdateLoop()

socket.on 'gamestate', (gamestate) ->
  console.log 'got game state', gamestate
  GAME_STATE = gamestate

