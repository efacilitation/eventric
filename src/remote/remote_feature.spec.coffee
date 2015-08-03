describe 'Remote Feature', ->

  exampleContext  = null
  exampleRemote = null
  doSomethingCommandHandlerStub = null
  getSomethingQueryHandlerStub = null

  beforeEach ->
    doSomethingCommandHandlerStub = sandbox.stub()
    getSomethingQueryHandlerStub = sandbox.stub()

    exampleContext = eventric.context 'Example'
    exampleContext.defineDomainEvents
      ExampleCreated: ->
      ExampleModified: ->


    exampleContext.addCommandHandlers
      CreateExample: (params) ->
        @$aggregate.create 'Example'
        .then (example) ->
          example.$save()


      ModifyExample: (params) ->
        @$aggregate.load 'Example', params.id
        .then (example) ->
          example.modify()
          example.$save()


      DoSomething: (params) ->
        doSomethingCommandHandlerStub params


    class ExampleAggregate
      create: ->
        @$emitDomainEvent 'ExampleCreated'

      modify: ->
        @$emitDomainEvent 'ExampleModified'


    exampleContext.addAggregate 'Example', ExampleAggregate

    exampleContext.addQueryHandlers
      getSomething: (params) ->
        new Promise (resolve) ->
          getSomethingQueryHandlerStub params
          resolve 'something'

    exampleContext.initialize()
    .then ->
      exampleRemote = eventric.remote 'Example'


  describe 'creating a remote for an example context', ->

    it 'should create a remote for the context', ->
      Remote = require 'eventric/src/remote'
      expect(exampleRemote).to.be.an.instanceof Remote


  describe 'executing a command on a remote', ->

    it 'should pass on the command to the context', ->
      params = {}
      exampleRemote.command 'DoSomething', params
      .then ->
        expect(doSomethingCommandHandlerStub).to.have.been.calledOnce
        expect(doSomethingCommandHandlerStub).to.have.been.calledWith params


  describe 'querying a remote', ->

    it 'should pass on the query to the context', ->
      params = {}
      exampleRemote.query 'getSomething', params
      .then (result) ->
        expect(getSomethingQueryHandlerStub).to.have.been.calledWith params
        expect(result).to.equal 'something'


  describe 'subscribing to an event on a remote', ->

    it 'should notify the subscriber in case of an event', (done) ->
      numberOfReceivedEvents = 0
      exampleRemote.subscribeToDomainEvent 'ExampleCreated', ->
        numberOfReceivedEvents++
        if numberOfReceivedEvents is 2
          done()

      exampleRemote.command 'CreateExample', {}
      exampleRemote.command 'CreateExample', {}


  describe 'subscribing for an event for a specific aggregate id on a remote', ->

    it 'should notify the subscriber in case of an event for the aggregate id', (done) ->
      exampleRemote.command 'CreateExample'
      .then (exampleId) ->
        exampleRemote.subscribeToDomainEventWithAggregateId 'ExampleModified', exampleId, ->
          done()
        exampleRemote.command 'ModifyExample',
          id: exampleId


  describe 'unsubscribing form an event on a remote', ->

    it 'should not notify the subscriber anymore', (done) ->
      firstHandler = sandbox.stub()
      exampleRemote.subscribeToDomainEvent 'ExampleCreated', firstHandler
      .then (subscriberId) ->
        exampleRemote.unsubscribeFromDomainEvent subscriberId
      .then ->
        exampleRemote.subscribeToDomainEvent 'ExampleCreated', ->
          expect(firstHandler).not.to.have.been.called
          done()
      .then ->
        exampleRemote.command 'CreateExample', {}


  describe 'finding domain events by on a remote', ->

    it 'should be possible to find domain events by name', ->
      exampleRemote.command 'CreateExample', {}
      .then ->
        exampleRemote.findDomainEventsByName 'ExampleCreated'
      .then (events) ->
        expect(events.length).to.equal 1


  describe 'trying to execute sensitive or private functions from a context on a remote', ->

    it 'should not be possible', ->
      exposedHandleRPCRequest = null

      verifyThatContextFunctionCannotBeCalled = (functionName) ->
        sandbox.spy exampleContext, functionName

        callback = sandbox.spy()
        exposedHandleRPCRequest(
          contextName: 'Example', functionName: functionName, params: {}
          callback
        )

        expect(callback.getCall(0).args[0].message).to.match /not allowed/
        expect(exampleContext[functionName]).not.to.have.been.called


      eventric.addRemoteEndpoint 'test',
        setRPCHandler: (_handleRPCRequest) ->
          exposedHandleRPCRequest = _handleRPCRequest

      verifyThatContextFunctionCannotBeCalled '_initializeProjections'
      verifyThatContextFunctionCannotBeCalled '_initializeStore'


  describe 'creating and initializing some example context with a custom remote endpoint', ->
    communicationFake = null
    beforeEach ->
      class CustomRemoteEndpoint
        constructor: ->
          communicationFake = (rpcRequest) =>
            new Promise (resolve, reject) =>
              @_handleRPCRequest rpcRequest, (error, result) ->
                return reject error if error
                resolve result


        setRPCHandler: (@_handleRPCRequest) ->

      eventric.addRemoteEndpoint 'custom', new CustomRemoteEndpoint


    it 'should be able to receive commands over the custom remote client', (done) ->
      class CustomRemoteClient
        rpc: (rpcRequest) ->
          communicationFake rpcRequest

      exampleRemote.addClient 'custom', new CustomRemoteClient
      exampleRemote.set 'default client', 'custom'
      exampleRemote.command 'DoSomething'
      .then ->
        expect(doSomethingCommandHandlerStub).to.have.been.calledOnce
        done()
