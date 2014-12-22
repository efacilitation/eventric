describe 'Command Aggregate Feature', ->

  describe 'given we created and initialized some example context including an aggregate', ->
    exampleContext = null
    beforeEach (done) ->
      exampleContext = eventric.context 'exampleContext'
      exampleContext.defineDomainEvent 'ExampleCreated', ->
      exampleContext.defineDomainEvent 'SomethingHappened', (params) ->
        @someId   = params.someId
        @someProp = params.someProp
        @entity   = params.entity

      class Example
        create: (callback) ->
          @$emitDomainEvent 'ExampleCreated'
          callback()

        doSomething: (someId) ->
          @$emitDomainEvent 'SomethingHappened',
            someId: someId
            someProp: 'foo'

        handleSomethingHappened: (domainEvent) ->
          @someId = domainEvent.payload.someId
          @someProp = domainEvent.payload.someProp
      exampleContext.addAggregate 'Example', Example

      exampleContext.addCommandHandlers
        CreateExample: (params, callback) ->
          exampleId = null
          @$aggregate.create 'Example'
          .then (example) ->
            example.$save()
          .then (exampleId) ->
            callback null, exampleId

        DoSomething: (params, callback) ->
          @$aggregate.load 'Example', params.id
          .then (example) ->
            example.doSomething [1]
            example.$save()
          .then ->
            callback()

      exampleContext.initialize()
      .then ->
        done()


    describe 'when we send a command to the context', ->

      it 'then it should have triggered the correct DomainEvent', (done) ->
        exampleContext.subscribeToDomainEvent 'SomethingHappened', (domainEvent) ->
          expect(domainEvent.payload.someProp).to.equal 'foo'
          expect(domainEvent.name).to.equal 'SomethingHappened'
          done()

        exampleContext.command 'CreateExample'
        .then (exampleId) ->
          exampleContext.command 'DoSomething', id: exampleId


    describe 'when we send multiple commands to the context', ->

      it 'then it should execute all commands as expected', (done) ->
        commandCount = 0
        exampleContext.subscribeToDomainEvent 'SomethingHappened', (domainEvent) ->
          commandCount++

          if commandCount == 2
            expect(commandCount).to.equal 2
            done()

        exampleContext.command 'CreateExample'
        .then (exampleId) ->
          exampleContext.command 'DoSomething', id: exampleId
          exampleContext.command 'DoSomething', id: exampleId

