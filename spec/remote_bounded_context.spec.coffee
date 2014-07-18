describe 'Remote Bounded MicroContext', ->
  RemoteService        = eventric.require 'RemoteService'
  RemoteMicroContext = eventric.require 'RemoteMicroContext'

  describe '#command', ->

    it 'should tell the RemoteService to execute a command on the MicroContext', ->
      microContextName = 'exampleMicroContext'
      command =
        name: 'ExampleAggregate:doSomething'
        id: 42

      callback = ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteMicroContext = new RemoteMicroContext remoteServiceStub
      remoteMicroContext.command microContextName, command, callback

      expectedRpc =
        microContextName: microContextName
        method: 'command'
        params:
          name: 'ExampleAggregate:doSomething'
          id: 42

      expect(remoteServiceStub.rpc.calledWith 'RemoteMicroContext', expectedRpc, callback).to.be.true


  describe '#query', ->

    it 'should tell the RemoteService to execute a query on the MicroContext', ->
      microContextName = 'exampleMicroContext'
      query =
        name: 'ExampleAggregate:findById'
        id: 23

      callback = ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteMicroContext = new RemoteMicroContext remoteServiceStub
      remoteMicroContext.query microContextName, query, callback

      expectedRpc =
        microContextName: microContextName
        method: 'query'
        params:
          name: 'ExampleAggregate:findById'
          id: 23

      expect(remoteServiceStub.rpc.calledWith 'RemoteMicroContext', expectedRpc).to.be.true

  describe '#rpc', ->

    it 'should call the RemoteService', ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteMicroContext = new RemoteMicroContext remoteServiceStub
      remoteMicroContext.rpc {some: 'rpc'}

      expect(remoteServiceStub.rpc.calledWith 'RemoteMicroContext', {some: 'rpc'}).to.be.true

  describe '#handle', ->

    it 'should execute the method:params on the correct bounded microContext given in the rpc payload', ->

      class ExampleMicroContext
        command: ->

      exampleMicroContext = sinon.createStubInstance ExampleMicroContext

      callback = ->
      microContextName = 'exampleMicroContext'
      command =
        name: 'ExampleAggregate:doSomething'
        id: 42
        params:
          foo: 'bar'

      rpc =
        payload:
          microContextName: microContextName
          method: 'command'
          params: command

      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteMicroContext = new RemoteMicroContext remoteServiceStub
      remoteMicroContext.registerMicroContextObj 'exampleMicroContext', exampleMicroContext
      remoteMicroContext.handle rpc.payload, callback

      expect(exampleMicroContext.command.calledWith command, callback).to.be.true