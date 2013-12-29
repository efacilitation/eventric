describe 'SocketIOAdapter', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  SocketIOAdapter = eventric 'RepositorySocketIOAdapter'
  SocketIOService = eventric 'SocketService'



  describe '#findById', ->

    it 'should emit a Repository Event with the given findById-method and params through SocketIO', ->

      socketIOService = sinon.createStubInstance SocketIOService

      adapter = new SocketIOAdapter socketIOService

      adapter.findById 42

      socketEvent =
        name: 'repository'
        data:
          method: 'findById'
          id: 42

      expect(socketIOService.emit.calledWith socketEvent).to.be.ok()