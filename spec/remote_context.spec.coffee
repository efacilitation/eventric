describe 'Remote Context', ->
  RemoteService = eventric.require 'RemoteService'
  RemoteContext = eventric.require 'RemoteContext'

  describe '#command', ->

    it 'should tell the RemoteService to execute a command on the context', ->
      contextName = 'exampleContext'
      command =
        name: 'ExampleAggregate:doSomething'
        id: 42

      callback = ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remotecontext = new RemoteContext remoteServiceStub
      remotecontext.command contextName, command, callback

      expectedRpc =
        contextName: contextName
        method: 'command'
        params:
          name: 'ExampleAggregate:doSomething'
          id: 42

      expect(remoteServiceStub.rpc.calledWith 'RemoteContext', expectedRpc, callback).to.be.true


  describe '#query', ->

    it 'should tell the RemoteService to execute a query on the context', ->
      contextName = 'exampleContext'
      query =
        name: 'ExampleAggregate:findById'
        id: 23

      callback = ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remotecontext = new RemoteContext remoteServiceStub
      remotecontext.query contextName, query, callback

      expectedRpc =
        contextName: contextName
        method: 'query'
        params:
          name: 'ExampleAggregate:findById'
          id: 23

      expect(remoteServiceStub.rpc.calledWith 'RemoteContext', expectedRpc).to.be.true

  describe '#rpc', ->

    it 'should call the RemoteService', ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remotecontext = new RemoteContext remoteServiceStub
      remotecontext.rpc {some: 'rpc'}

      expect(remoteServiceStub.rpc.calledWith 'RemoteContext', {some: 'rpc'}).to.be.true

  describe '#handle', ->

    it 'should execute the method:params on the correct context given in the rpc payload', ->

      class Examplecontext
        command: ->

      exampleContext = sinon.createStubInstance Examplecontext

      callback = ->
      contextName = 'exampleContext'
      command =
        name: 'ExampleAggregate:doSomething'
        id: 42
        params:
          foo: 'bar'

      rpc =
        payload:
          contextName: contextName
          method: 'command'
          params: command

      remoteServiceStub = sinon.createStubInstance RemoteService
      remotecontext = new RemoteContext remoteServiceStub
      remotecontext.registerContextObj 'exampleContext', exampleContext
      remotecontext.handle rpc.payload, callback

      expect(exampleContext.command.calledWith command, callback).to.be.true