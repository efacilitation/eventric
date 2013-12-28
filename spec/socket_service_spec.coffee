describe 'SocketService', ->

  _        = require 'underscore'
  expect   = require 'expect'
  sinon    = require 'sinon'
  eventric = require 'eventric'

  class StubDomainEventService
    process: sinon.stub().callsArg(1)

  SocketService = eventric 'SocketService'

  sessionUser            = null
  socketService          = null
  stubSocket             = null
  stubIO                 = null
  stubDomainEventService = null

  beforeEach ->
    sessionUser = { _id: 1 }

    stubSocket =
      handshake: session: user: sessionUser
      on:   sinon.stub()
      emit: sinon.stub()

    stubIO =
      sockets:
        on: sinon.stub()

    stubDomainEventService = new StubDomainEventService

    socketService = new SocketService stubDomainEventService, stubIO

  afterEach ->
    stubIO.sockets.on.reset()
    stubSocket.on.reset()

  describe 'given Socket.IO-Server provided as _io parameter', ->

    beforeEach ->
      socketService = new SocketService stubDomainEventService, stubIO

    it 'should listen to Socket.IO connections ', ->
      listener       = stubIO.sockets.on
      initConnection = socketService.initConnection
      expect(listener.calledWith 'connection', initConnection).to.be true
      expect(socketService._socket).not.to.be.ok()

  describe 'given Socket.IO-Socket provided as _io parameter', ->

    beforeEach ->
      socketService = new SocketService stubDomainEventService, stubSocket

    it 'should initialize a socket.io listener for domain events', ->
      expect(socketService._socket).to.be.ok()
      expect(socketService._socket.on.calledWith 'domainEvent', socketService.receive).to.be true

  describe 'on Socket.IO Client connection', ->

    beforeEach ->
      socketService.initConnection stubSocket

    it 'should initialize a socket.io listener for domain events', ->
      socket  = socketService._socket
      receive = socketService.receive
      expect(socket.on.calledWith('domainEvent', receive)).to.be.ok()

    describe 'on receiving a domain event', ->

      domainEvent = null

      beforeEach ->
        domainEvent = {}
        socketService.receive domainEvent

      it 'should append the session user to the domain event object', ->
        expect(domainEvent.sessionUser).to.be sessionUser

      it 'should pass the domain event to be processed by the domain event service', ->
        process = stubDomainEventService.process
        expect(process.calledWith domainEvent).to.be.ok()

      it 'should emit the domain event after the domain event service has processed', ->
        expect(socketService._socket.emit.callCount).to.be 1

    describe '#emit', ->

      it 'should emit a domain event through the Socket.IO connection', ->
        domainEvent = {}
        socketService.emit domainEvent
        expect(socketService._socket.emit.calledWith 'domainEvent', domainEvent).to.be.ok()

  describe 'without a Socket.IO connection', ->

    describe '#emit', ->

      it 'should throw an error', ->
        expect(socketService.emit).to.throwError()
