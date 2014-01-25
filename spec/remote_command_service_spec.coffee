describe 'RemoteCommandService', ->

  expect   = require 'expect.js'
  sinon    = require 'sinon'
  eventric = require 'eventric'

  RemoteService        = eventric 'RemoteService'
  RemoteCommandService = eventric 'RemoteCommandService'

  describe '#createAggregate', ->

    it 'should tell the RemoteService to create an Aggregate with the given name', ->

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


  describe '#commandAggregate', ->

    it 'should tell the RemoteService to command the Aggregate with the given name/id', ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteCommandService = new RemoteCommandService remoteServiceStub
      remoteCommandService.commandAggregate 'ExampleAggregate', 42, 'someMethod', {some: 'params'}

      expectedRpc =
        class: 'CommandService'
        method: 'commandAggregate'
        params: [
          'ExampleAggregate'
          42
          'someMethod'
          {some: 'params'}
        ]

      expect(remoteServiceStub.rpc.calledWith expectedRpc).to.be.ok()