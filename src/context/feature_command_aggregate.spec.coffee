describe 'Command Aggregate Feature', ->

  describe 'given we created and initialized some example context including an aggregate', ->
    exampleContext = null
    beforeEach (done) ->
      exampleContext = eventric.context 'exampleContext'
      exampleContext.addAggregate 'Example', class Example

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

        handleExampleCreated: ->
          @entities = []

        handleSomethingHappened: (domainEvent) ->
          @someId = domainEvent.payload.someId
          @someProp = domainEvent.payload.someProp
      exampleContext.addAggregate 'Example', Example

      exampleContext.addCommandHandlers
        CreateExample: (params, callback) ->
          exampleId = null
          @$repository('Example').create()
          .then (exampleId) =>
            @$repository('Example').save exampleId
          .then (exampleId) ->
            callback null, exampleId

        DoSomething: (params, callback) ->
          @$repository('Example').findById params.id
          .then (example) =>
            example.doSomething [1]
            @$repository('Example').save params.id
          .then ->
            callback()

      exampleContext.initialize ->
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

