describe 'Create Aggregate Feature', ->

  describe 'given we created and initialized some example context including an aggregate', ->

    describe 'when we command the context to create an aggregate', ->

      it 'should call the create function on the aggregate with the given params', (done) ->
        exampleContext = eventric.context 'Examplecontext'

        exampleContext.defineDomainEvent 'ExampleCreated', (params) ->
          expect(params.name).to.equal 'John'
          expect(params.email).to.equal 'some@where'

        createCalled = false
        class Example
          create: (params) ->
            createCalled = true
            @$emitDomainEvent 'ExampleCreated', params

        exampleContext.addAggregate 'Example', Example

        exampleContext.addCommandHandlers
          CreateExample: (params) ->
            @$aggregate.create 'Example', name: 'John', email: 'some@where'
            .then (example) ->
              example.$save()

        exampleContext.initialize()
        .then ->
          exampleContext.command 'CreateExample',
            name: 'MyName'
            email: 'MyEmail'
          .then ->
            expect(createCalled).to.be.true
            done()

