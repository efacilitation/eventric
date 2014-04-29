describe 'Remote Bounded Context', ->

  expect   = require 'expect.js'
  sinon    = require 'sinon'
  eventric = require 'eventric'
  RemoteService        = eventric 'RemoteService'
  RemoteBoundedContext = eventric 'RemoteBoundedContext'

  describe '#command', ->

    it 'should tell the RemoteService to execute a command on the BoundedContext', ->
      boundedContextName = 'exampleContext'
      commandName = 'ExampleAggregate:doSomething'
      commandPayload =
        aggregateId: 42

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteBoundedContext = new RemoteBoundedContext remoteServiceStub
      remoteBoundedContext.command boundedContextName, commandName, commandPayload

      expectedRpc =
        class: 'BoundedContext'
        method: 'command'
        params: [
          boundedContextName
          commandName
          commandPayload
        ]

      expect(remoteServiceStub.rpc.calledWith 'RemoteBoundedContext', expectedRpc).to.be.ok()


  describe '#query', ->

    it 'should tell the RemoteService to execute a query on the BoundedContext', ->
      boundedContextName = 'exampleContext'
      queryName = 'ExampleAggregate:findById'
      queryPayload =
        aggregateId: 23

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteBoundedContext = new RemoteBoundedContext remoteServiceStub
      remoteBoundedContext.query boundedContextName, queryName, queryPayload

      expectedRpc =
        class: 'BoundedContext'
        method: 'query'
        params: [
          boundedContextName
          queryName
          queryPayload
        ]

      expect(remoteServiceStub.rpc.calledWith 'RemoteBoundedContext', expectedRpc).to.be.ok()

  describe '#rpc', ->

    it 'should call the RemoteService', ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteBoundedContext = new RemoteBoundedContext remoteServiceStub
      remoteBoundedContext.rpc {some: 'rpc'}

      expect(remoteServiceStub.rpc.calledWith 'RemoteBoundedContext', {some: 'rpc'}).to.be.ok()

  describe '#handle', ->

    it 'should execute the method:params on the correct bounded context given in the rpc payload', ->

      class ExampleContext
        command: ->

      exampleContext = sinon.createStubInstance ExampleContext

      boundedContextName = 'exampleContext'
      commandName = 'ExampleAggregate:doSomething'
      commandPayload =
        aggregateId: 42

      rpc =
        payload:
          class: 'BoundedContext'
          method: 'command'
          params: [
            boundedContextName
            commandName
            commandPayload
          ]

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteBoundedContext = new RemoteBoundedContext remoteServiceStub
      remoteBoundedContext.registerClass 'exampleContext', exampleContext
      remoteBoundedContext.handle rpc.payload, ->

      command =
        name: commandName
        params: commandPayload
      expect(exampleContext.command.calledWith command).to.be.ok()