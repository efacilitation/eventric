class SocketIORemoteService

  constructor: (@_domainEventService, @_io) ->
    if @_io.sockets
      @_io.sockets.on 'connection', @initConnection
    else
      @_socket = @_io
      @_initSocketDomainEventListener()
    @

  initConnection: (socket) =>
    @_socket      = socket
    @_handshake   = socket.handshake
    @_sessionUser = @_handshake?.session?.user
    @_initSocketDomainEventListener()
    @

  _initSocketDomainEventListener: ->
    @_socket.on 'domainEvent', @receive, @
    @

  receive: (domainEvent) =>
    domainEvent.sessionUser = @_sessionUser
    @_domainEventService.process domainEvent, @emit
    @

  emit: (domainEvent) =>
    unless @_socket
      throw new Error 'emit called without active socket connection'
    @_socket.emit 'domainEvent', domainEvent
    @

module.exports = SocketIORemoteService
