describe 'Context Feature', ->

  describe '#emitDomainEvent', ->

    describe 'given the domain event is registered on the context', ->

      exampleContext = null

      beforeEach ->
        exampleContext = eventric.context 'ExampleContext'
        exampleContext.defineDomainEvent 'SomeEvent', ->

      it 'should publish the domain event', (done) ->
        exampleContext.subscribeToDomainEvent 'SomeEvent', (domainEvent) ->
          expect(domainEvent).to.be.ok
          done()
        exampleContext.initialize()
        .then ->
          exampleContext.emitDomainEvent 'SomeEvent', {}
        .catch done


      it 'should save the domain event', (done) ->
        exampleContext.initialize()
        .then ->
          exampleContext.emitDomainEvent 'SomeEvent', {}
        .then ->
          exampleContext.getDomainEventsStore().findDomainEventsByName 'SomeEvent', (error, domainEvents) ->
            expect(domainEvents.length).to.equal 1
            expect(domainEvents[0].name).to.equal 'SomeEvent'
            done()
        .catch done