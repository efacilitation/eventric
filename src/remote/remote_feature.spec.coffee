describe 'Remote Feature', ->
  exampleContext  = null
  doSomethingStub = null
  beforeEach (done) ->
    doSomethingStub = sandbox.stub()

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

      DoSomething: (params, promise) ->
        doSomethingStub()
        promise.resolve null

    class Example
      create: ->
        @$emitDomainEvent 'ExampleCreated'

      modify: ->
        @$emitDomainEvent 'ExampleModified'


    exampleContext.addAggregate 'Example', Example

    exampleContext.addQueryHandlers
      getSomething: (params, promise) ->
        promise.resolve 'something'

    exampleContext.initialize()
    .then ->
      done()


  describe 'given we created and initialized some example context', ->
    it 'then it should be able to receive commands over a remote', ->
      exampleRemote = eventric.remote 'Example'
      exampleRemote.command 'DoSomething'
      .then ->
        expect(doSomethingStub).to.have.been.calledOnce


    it 'then it should be able to answer queries over a remote', ->
      exampleRemote = eventric.remote 'Example'
      exampleRemote.query 'getSomething'
      .then (result) ->
        expect(result).to.equal 'something'


    it 'then it should be possible to subscribe to domain events and receive them', (done) ->
      exampleRemote = eventric.remote 'Example'

      numberOfReceivedEvents = 0
      exampleRemote.subscribeToDomainEvent 'ExampleCreated', ->
        numberOfReceivedEvents++
        if numberOfReceivedEvents is 2
          done()

      exampleRemote.command 'CreateExample', {}
      exampleRemote.command 'CreateExample', {}


    it 'then it should be possible to subscribe to domain events for specific aggregate ids', (done) ->
      exampleRemote = eventric.remote 'Example'

      exampleRemote.command 'CreateExample'
      .then (exampleId) ->
        exampleRemote.subscribeToDomainEventWithAggregateId 'ExampleModified', exampleId, ->
          done()
        exampleRemote.command 'ModifyExample',
          id: exampleId


    it 'then it should be possible to unsubscribe from domain events', (done) ->
      exampleRemote = eventric.remote 'Example'
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


    it 'then it should be possible to find all domain events', ->
      exampleRemote = eventric.remote 'Example'
      exampleRemote.command 'CreateExample', {}
      .then (id) ->
        exampleRemote.command 'ModifyExample', id: id
      .then ->
        exampleRemote.findAllDomainEvents()
      .then (events) ->
        expect(events.length).to.equal 2


    it 'then it should be possible to find domain events by name', ->
      exampleRemote = eventric.remote 'Example'
      exampleRemote.command 'CreateExample', {}
      .then ->
        exampleRemote.findDomainEventsByName 'ExampleCreated'
      .then (events) ->
        expect(events.length).to.equal 1


    it 'then it should be possible to find domain events by aggregate id', ->
      exampleRemote = eventric.remote 'Example'
      exampleRemote.command 'CreateExample', {}
      .then (id) ->
        exampleRemote.findDomainEventsByAggregateId id
      .then (events) ->
        expect(events.length).to.equal 1


    it 'then it should be possible to find domain events by aggregate name', ->
      exampleRemote = eventric.remote 'Example'
      exampleRemote.command 'CreateExample', {}
      .then ->
        exampleRemote.findDomainEventsByAggregateName 'Example'
      .then (events) ->
        expect(events.length).to.equal 1


  describe 'given we created and initialized some example context with a custom remote endpoint', ->
    customRemoteBridge = null
    beforeEach ->
      class CustomRemoteEndpoint
        constructor: ->
          customRemoteBridge = (rpcRequest) =>
            new Promise (resolve, reject) =>
              @_handleRPCRequest rpcRequest, (error, result) ->
                return reject error if error
                resolve result


        setRPCHandler: (@_handleRPCRequest) ->

      eventric.addRemoteEndpoint 'custom', new CustomRemoteEndpoint


    it 'then it should be able to receive commands over the custom remote client', (done) ->
      class CustomRemoteClient
        rpc: (rpcRequest) ->
          console.log rpcRequest
          customRemoteBridge rpcRequest

      exampleRemote = eventric.remote 'Example'
      exampleRemote.addClient 'custom', new CustomRemoteClient
      exampleRemote.set 'default client', 'custom'
      exampleRemote.command 'DoSomething'
      .then ->
        expect(doSomethingStub).to.have.been.calledOnce
        done()
