describe 'Subscribe to event with aggregate id Feature', ->

  describe 'given we created and initialized some example context including an aggregate', ->
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.context 'exampleContext'
      exampleContext.addAggregate 'Example', class Example

      exampleContext.defineDomainEvent 'ExampleCreated', ->
      exampleContext.defineDomainEvent 'SomethingHappened', ->
      class Example
        create: ->
          @$emitDomainEvent 'ExampleCreated'

        doSomething: ->
          @$emitDomainEvent 'SomethingHappened'
      exampleContext.addAggregate 'Example', Example

      exampleContext.addCommandHandlers
        CreateExample: (params) ->
          exampleId = null
          @$aggregate.create 'Example'
          .then (example) ->
            example.$save()

        DoSomething: (params) ->
          @$aggregate.load 'Example', params.id
          .then (example) ->
            example.doSomething()
            example.$save()

      exampleContext.initialize()


    describe 'when we subscribe to an event with a specific aggregate id', ->

      it 'should notify the domain event subscriber if the aggregate id matches', ->
        handlerFn = sandbox.spy()
        exampleContext.command 'CreateExample'
        .then (exampleId) ->
          exampleContext.subscribeToDomainEventWithAggregateId 'SomethingHappened', exampleId, handlerFn
          exampleContext.command 'DoSomething', id: exampleId
        .then ->
          expect(handlerFn).to.have.been.called


      it 'should not notify the domain event subscriber if the aggregate does not match', ->
        handlerFn = sandbox.spy()
        exampleContext.command 'CreateExample'
        .then (exampleId) ->
          anotherId = exampleId + '12345'
          exampleContext.subscribeToDomainEventWithAggregateId 'SomethingHappened', anotherId, handlerFn
          exampleContext.command 'DoSomething', id: exampleId
        .then ->
          expect(handlerFn).not.to.have.been.called