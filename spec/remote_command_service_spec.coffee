describe 'RemoteCommandService', ->

  expect   = require 'expect.js'
  sinon    = require 'sinon'
  eventric = require 'eventric'

  RemoteService        = eventric 'RemoteService'
  RemoteCommandService = eventric 'RemoteCommandService'

  describe '#createAggregate', ->

    it 'should call the RemoteService to create an Aggregate with the given name using RPC', ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteCommandService = new RemoteCommandService remoteServiceStub
      remoteCommandService.createAggregate 'ExampleAggregate'

      expectedRpc =
        class: 'CommandService'
        method: 'createAggregate'
        params: [
          'ExampleAggregate'
        ]

      expect(remoteServiceStub.rpc.calledWith expectedRpc).to.be.ok()