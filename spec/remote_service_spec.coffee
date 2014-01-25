describe 'RemoteService', ->

  expect   = require 'expect.js'
  sinon    = require 'sinon'
  eventric = require 'eventric'

  RemoteService = eventric 'RemoteService'

  describe '#rpc', ->

    it 'call the rpc methid on the given RemoteServiceAdapter', ->

      class ExampleRemoteServiceAdapter
        rpc: ->

      remoteServiceAdapter = sinon.createStubInstance ExampleRemoteServiceAdapter

      remoteService = new RemoteService remoteServiceAdapter

      remoteService.rpc()

      expect(remoteServiceAdapter.rpc.calledOnce).to.be.ok()