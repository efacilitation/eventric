describe 'Create Aggregate Feature', ->

  describe 'given we created and initialized some example context including an aggregate', ->

    describe 'when we command the context to create an aggregate', ->

      it 'should call the create function on the aggregate with the given params', (done) ->
        exampleContext = eventric.context 'Examplecontext'

        exampleContext.addDomainEvent 'ExampleCreated', (params) ->

        exampleContext.addAggregate 'Example', class Example
          create: sandbox.stub()

        exampleContext.addCommandHandler 'CreateExample', (params, done) ->
          @$repository('Example').create params.name, params.email
          .then (exampleId) =>
            @$repository('Example').save exampleId
          .then =>
            done()

        exampleContext.initialize ->
          exampleContext.command 'CreateExample',
            name: 'MyName'
            email: 'MyEmail'

          expect(Example::create).to.have.been.calledWith 'MyName', 'MyEmail'
          done()
