describe 'Command Aggregate Feature', ->

  describe 'given we created and initialized some example context including an aggregate', ->
    exampleContext = null

    beforeEach ->
      exampleContext = eventric.context 'exampleContext'

      # Domain Events
      exampleContext.defineDomainEvent 'ExampleCreated', ->
      exampleContext.defineDomainEvent 'SomethingHappened', (params) ->
        @someId   = params.someId
        @someProperty = params.someProperty


      class ExampleAggregate
        create: ->
          @$emitDomainEvent 'ExampleCreated'

        doSomething: (someId, someProperty) ->
          @$emitDomainEvent 'SomethingHappened',
            someId: someId
            someProperty: someProperty

        handleSomethingHappened: (domainEvent) ->
          @someId = domainEvent.payload.someId
          @someProperty = domainEvent.payload.someProperty

      exampleContext.addAggregate 'Example', ExampleAggregate

      exampleContext.addCommandHandlers
        CreateExample: (params) ->
          exampleId = null
          @$aggregate.create 'Example'
          .then (example) ->
            example.$save()


        DoSomething: (params) ->
          @$aggregate.load 'Example', params.aggregateId
          .then (example) ->
            example.doSomething params.someId, params.someProperty
            example.$save()

      exampleContext.initialize()


    describe 'sending a command to the context', ->

      it 'should trigger the correct DomainEvent', (done) ->
        exampleContext.subscribeToDomainEvent 'SomethingHappened', (domainEvent) ->
          expect(domainEvent.payload.someId).to.equal 'some-id'
          expect(domainEvent.payload.someProperty).to.equal 'some-property'
          expect(domainEvent.name).to.equal 'SomethingHappened'
          done()

        exampleContext.command 'CreateExample'
        .then (exampleId) ->
          exampleContext.command 'DoSomething',
            aggregateId: exampleId
            someId: 'some-id'
            someProperty: 'some-property'


    describe 'sending multiple commands to the context', ->

      it 'should execute all commands as expected', (done) ->
        commandCount = 0
        exampleContext.subscribeToDomainEvent 'SomethingHappened', (domainEvent) ->
          commandCount++

          if commandCount == 2
            expect(commandCount).to.equal 2
            done()

        exampleContext.command 'CreateExample'
        .then (exampleId) ->
          exampleContext.command 'DoSomething',
            aggregateId: exampleId
            someId: 'some-id'
            someProperty: 'some-property'
          exampleContext.command 'DoSomething',
            aggregateId: exampleId
            someId: 'some-id'
            someProperty: 'some-property'


    describe '[bugfix] returning an array at the domain event definition', ->

      it 'should also return the whole domain event properties as payload', (done) ->
        exampleContext.subscribeToDomainEvent 'SomethingHappened', (domainEvent) ->
          expect(domainEvent.payload).to.deep.equal
            someId: 'some-id'
            someProperty: ['value-1', 'value-2']
          done()

        exampleContext.command 'CreateExample'
        .then (exampleId) ->
          exampleContext.command 'DoSomething',
            aggregateId: exampleId
            someId: 'some-id'
            someProperty: ['value-1', 'value-2']
