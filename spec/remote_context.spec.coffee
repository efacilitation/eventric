describe 'Remote Context', ->
  RemoteService = require 'eventric/remote_service'
  RemoteContext = require 'eventric/remote_context'

  describe '#command', ->

    it 'should tell the RemoteService to execute a command on the context', ->
      contextName = 'exampleContext'

      callback = ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remotecontext = new RemoteContext remoteServiceStub
      remotecontext.command contextName, 'doSomething', id: 42, callback

      expectedRpc =
        contextName: contextName
        method: 'command'
        params:['doSomething', id: 42]

      expect(remoteServiceStub.rpc.calledWith 'RemoteContext', expectedRpc, callback).to.be.true


  describe '#query', ->

    it 'should tell the RemoteService to execute a query on the context', ->
      contextName = 'exampleContext'
      callback = ->

      remoteServiceStub = sinon.createStubInstance RemoteService
      remotecontext = new RemoteContext remoteServiceStub
      remotecontext.query contextName, 'getSomething', id: 23, callback

      expectedRpc =
        contextName: contextName
        method: 'query'
        params: ['getSomething', id: 23]

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
      rpc =
        payload:
          contextName: 'exampleContext'
          method: 'command'
          params: ['doSomething', foo: 'bar']

      remoteServiceStub = sinon.createStubInstance RemoteService
      remotecontext = new RemoteContext remoteServiceStub
      remotecontext.registerContextObj 'exampleContext', exampleContext
      remotecontext.handle rpc.payload, callback

      expect(exampleContext.command.calledWith 'doSomething', foo: 'bar', callback).to.be.true