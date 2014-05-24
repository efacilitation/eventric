describe 'RemoteCommandService', ->
  RemoteService        = eventric.require 'RemoteService'
  RemoteCommandService = eventric.require 'RemoteCommandService'

  describe '#createAggregate', ->
    it 'should tell the RemoteService to create an Aggregate with the given name', ->
      callback = ->
      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteCommandService = new RemoteCommandService remoteServiceStub
      remoteCommandService.createAggregate 'ExampleAggregate', callback

      expectedRpc =
        class: 'CommandService'
        method: 'createAggregate'
        params: [
          'ExampleAggregate'
        ]

      expect(remoteServiceStub.rpc.calledWith 'RemoteCommandService', expectedRpc, callback).to.be.true


  describe '#commandAggregate', ->
    it 'should tell the RemoteService to command the Aggregate with the given name/id', ->
      callback = ->
      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteCommandService = new RemoteCommandService remoteServiceStub
      remoteCommandService.commandAggregate 'ExampleAggregate', 42, 'someMethod', {some: 'params'}, callback

      expectedRpc =
        class: 'CommandService'
        method: 'commandAggregate'
        params: [
          'ExampleAggregate'
          42
          'someMethod'
          {some: 'params'}
        ]

      expect(remoteServiceStub.rpc.calledWith 'RemoteCommandService', expectedRpc, callback).to.be.true


  describe '#rpc', ->
    it 'should call the RemoteService', ->
      remoteServiceStub = sinon.createStubInstance RemoteService
      remoteCommandService = new RemoteCommandService remoteServiceStub
      remoteCommandService.rpc {some: 'rpc'}

      expect(remoteServiceStub.rpc.calledWith 'RemoteCommandService', {some: 'rpc'}).to.be.true


  describe '#handle', ->
    it 'should execute the class:method:params given in the rpc payload', ->
      class CommandServiceStub
        commandAggregate: ->

      commandServiceStub = sinon.createStubInstance CommandServiceStub

      rpc =
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
      remoteCommandService.registerClass 'CommandService', commandServiceStub
      remoteCommandService.handle rpc.payload, ->

      expect(commandServiceStub.commandAggregate.calledWith rpc.payload.params...).to.be.true