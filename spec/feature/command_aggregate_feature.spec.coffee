describe 'Command Aggregate Feature', ->

  describe 'given we created and initialized some example context including an aggregate', ->
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.context 'exampleContext'
      exampleContext.addAggregate 'Example', class Example


    describe 'when we send a command to the context', ->
      beforeEach (done) ->
        exampleContext.addDomainEvent 'ExampleCreated', ->
        exampleContext.addDomainEvent 'SomethingHappened', (params) ->
          @someId   = params.someId
          @someProp = params.someProp
          @entity   = params.entity

        exampleContext.addAggregate 'Example', ->
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


      it 'then it should have triggered the correct DomainEvent', (done) ->
        exampleContext.addDomainEventHandler 'SomethingHappened', (domainEvent) ->
          expect(domainEvent.payload.someProp).to.equal 'foo'
          expect(domainEvent.name).to.equal 'SomethingHappened'
          done()

        exampleContext.command 'CreateExample'
        .then (exampleId) ->
          exampleContext.command 'DoSomething', id: exampleId
