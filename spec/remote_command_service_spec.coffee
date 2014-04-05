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
      remoteCommandService.createAggregate 'ExampleAggregate', ->

      expectedRpc =
        class: 'CommandService'
        method: 'createAggregate'
        params: [
          'ExampleAggregate'
          undefined
        ]

      expect(remoteServiceStub.rpc.calledWith 'RemoteCommandService', expectedRpc).to.be.ok()


  describe '#commandAggregate', ->

    it 'should tell the RemoteService to command the Aggregate with the given name/id', ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteCommandService = new RemoteCommandService remoteServiceStub
      remoteCommandService.commandAggregate 'ExampleAggregate', 42, 'someMethod', {some: 'params'}, ->

      expectedRpc =
        class: 'CommandService'
        method: 'commandAggregate'
        params: [
          'ExampleAggregate'
          42
          'someMethod'
          {some: 'params'}
        ]

      expect(remoteServiceStub.rpc.calledWith 'RemoteCommandService', expectedRpc).to.be.ok()

  describe '#rpc', ->

    it 'should call the RemoteService', ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteCommandService = new RemoteCommandService remoteServiceStub
      remoteCommandService.rpc {some: 'rpc'}

      expect(remoteServiceStub.rpc.calledWith 'RemoteCommandService', {some: 'rpc'}).to.be.ok()

  describe '#handle', ->

    it 'should execute the class:method:params given in the rpc payload', ->

      class ExampleAggregate
        someMethod: ->

      exampleAggregate = sinon.createStubInstance ExampleAggregate

      rpc =
        service: 'RemoteCommandService'
        payload:
          class: 'CommandService'
          method: 'commandAggregate'
          params: [
            'ExampleAggregate'
            42
            'someMethod'
            {some: 'params'}
          ]

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteCommandService = new RemoteCommandService remoteServiceStub
      remoteCommandService.registerClass 'ExampleAggregate', exampleAggregate
      remoteCommandService.handle rpc, ->

      expect(exampleAggregate.someMethod.calledWith {some: 'params'})