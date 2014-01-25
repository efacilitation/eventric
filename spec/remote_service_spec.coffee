describe 'RemoteService', ->

  expect   = require 'expect.js'
  sinon    = require 'sinon'
  eventric = require 'eventric'

  RemoteService = eventric 'RemoteService'

  describe '#rpc', ->

    it 'call the rpc method on the RemoteServiceAdapter with the given parameters', ->

      class ExampleRemoteServiceAdapter
        rpc: ->

      remoteServiceAdapter = sinon.createStubInstance ExampleRemoteServiceAdapter

      remoteService = new RemoteService remoteServiceAdapter

      rpcPayload =
        class: 'ExampleAggregate'
        method: 'exampleMethod'
        params: [
          'exampleParams'
        ]

      remoteService.rpc rpcPayload

      expect(remoteServiceAdapter.rpc.calledWith rpcPayload).to.be.ok()