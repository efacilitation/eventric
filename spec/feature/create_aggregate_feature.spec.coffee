describe 'Create Aggregate Feature', ->

  describe 'given we created and initialized some example context including an aggregate', ->

    describe 'when we command the context to create an aggregate', ->

      it 'should call the create function on the aggregate with the given params', (done) ->
        exampleContext = eventric.context 'Examplecontext'

        exampleContext.addDomainEvent 'ExampleCreated', (params) ->

        class Example
          create: (name, email, callback) ->
            callback()
        sandbox.spy Example::, 'create'

        exampleContext.addAggregate 'Example', Example

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
          .then ->
            expect(Example::create).to.have.been.calledWith 'MyName', 'MyEmail', sinon.match.func
            done()
