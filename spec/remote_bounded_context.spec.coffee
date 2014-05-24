describe 'Remote Bounded Context', ->
  RemoteService        = eventric.require 'RemoteService'
  RemoteBoundedContext = eventric.require 'RemoteBoundedContext'

  describe '#command', ->

    it 'should tell the RemoteService to execute a command on the BoundedContext', ->
      boundedContextName = 'exampleContext'
      command =
        name: 'ExampleAggregate:doSomething'
        id: 42

      callback = ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteBoundedContext = new RemoteBoundedContext remoteServiceStub
      remoteBoundedContext.command boundedContextName, command, callback

      expectedRpc =
        boundedContextName: boundedContextName
        method: 'command'
        params:
          name: 'ExampleAggregate:doSomething'
          id: 42

      expect(remoteServiceStub.rpc.calledWith 'RemoteBoundedContext', expectedRpc, callback).to.be.true


  describe '#query', ->

    it 'should tell the RemoteService to execute a query on the BoundedContext', ->
      boundedContextName = 'exampleContext'
      query =
        name: 'ExampleAggregate:findById'
        id: 23

      callback = ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteBoundedContext = new RemoteBoundedContext remoteServiceStub
      remoteBoundedContext.query boundedContextName, query, callback

      expectedRpc =
        boundedContextName: boundedContextName
        method: 'query'
        params:
          name: 'ExampleAggregate:findById'
          id: 23

      expect(remoteServiceStub.rpc.calledWith 'RemoteBoundedContext', expectedRpc).to.be.true

  describe '#rpc', ->

    it 'should call the RemoteService', ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteBoundedContext = new RemoteBoundedContext remoteServiceStub
      remoteBoundedContext.rpc {some: 'rpc'}

      expect(remoteServiceStub.rpc.calledWith 'RemoteBoundedContext', {some: 'rpc'}).to.be.true

  describe '#handle', ->

    it 'should execute the method:params on the correct bounded context given in the rpc payload', ->

      class ExampleContext
        command: ->

      exampleContext = sinon.createStubInstance ExampleContext

      callback = ->
      boundedContextName = 'exampleContext'
      command =
        name: 'ExampleAggregate:doSomething'
        id: 42
        params:
          foo: 'bar'

      rpc =
        payload:
          boundedContextName: boundedContextName
          method: 'command'
          params: command

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteBoundedContext = new RemoteBoundedContext remoteServiceStub
      remoteBoundedContext.registerClass 'exampleContext', exampleContext
      remoteBoundedContext.handle rpc.payload, callback

      expect(exampleContext.command.calledWith command, callback).to.be.true