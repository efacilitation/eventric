describe 'Create Aggregate Feature', ->

  describe 'given we created and initialized some example context including an aggregate', ->

    describe 'when we command the context to create an aggregate', ->

      it 'should call the create function on the aggregate with the given params', (done) ->
        exampleContext = eventric.context 'Examplecontext'

        exampleContext.defineDomainEvent 'ExampleCreated', (params) ->

        class Example
          create: (name, email, callback) ->
            @$emitDomainEvent 'ExampleCreated'
            callback()
        sandbox.spy Example::, 'create'

        exampleContext.addAggregate 'Example', Example

        exampleContext.addCommandHandler 'CreateExample', (params, done) ->
          @$aggregate.create 'Example', params.name, params.email
          .then (example) =>
            example.$save()
          .then ->
            done()

        exampleContext.initialize ->
          exampleContext.command 'CreateExample',
            name: 'MyName'
            email: 'MyEmail'
          .then ->
            expect(Example::create).to.have.been.calledWith 'MyName', 'MyEmail', sinon.match.func
            done()
