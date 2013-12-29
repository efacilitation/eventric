class SocketIOAdapter

  constructor: (@_socketService) ->

  _createSocketEvent: (method, id) ->
    socketEvent =
      name: 'repository'
      data:
        method: method
        id: id

  findById: (id) ->
    @_socketService.emit @_createSocketEvent 'findById', id


module.exports = SocketIOAdapter