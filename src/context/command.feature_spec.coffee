describe 'Command Feature', ->

  it 'should reject with a descriptive error given the context was not initialized yet', ->
    someContext = eventric.context 'ExampleContext'
    someContext.command 'DoSomething'
    .catch (error) ->
      expect(error).to.be.an.instanceOf Error
      expect(error.message).to.contain 'ExampleContext'
      expect(error.message).to.contain 'DoSomething'


  it 'should reject with a command not found error given the command has no registered handler', ->
    someContext = eventric.context 'Examplecontext'
    someContext.initialize()
    .then ->
      someContext.command 'DoSomething',
        id: 42
        foo: 'bar'
    .catch (error) ->
      expect(error).to.be.an.instanceof Error


  it 'should call the command handler with the passed in params given the command has a registered handler', ->
    someContext = eventric.context 'Examplecontext'
    commandHandlerStub = sandbox.stub()
    someContext.addCommandHandlers DoSomething: commandHandlerStub
    params =
      id: 42
      foo: 'bar'
    someContext.initialize()
    .then ->
      someContext.command 'DoSomething', params
    .then ->
      expect(commandHandlerStub).to.have.been.calledWith params


  describe 'given a created and initialized example context including an aggregate', ->
    exampleContext = null

    beforeEach ->
      exampleContext = eventric.context 'exampleContext'

      # Domain Events
      exampleContext.defineDomainEvent 'ExampleCreated', ->
      exampleContext.defineDomainEvent 'SomethingHappened', (params) ->
        @someId = params.someId
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
          @$aggregate.create 'Example'
          .then (example) ->
            example.$save()


        DoSomething: (params) ->
          @$aggregate.load 'Example', params.aggregateId
          .then (example) ->
            example.doSomething params.someId, params.someProperty
            example.$save()

      exampleContext.initialize()


    it 'should trigger the correct domain event given one command is sent to the context', (done) ->
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
      .catch done
      return


    it 'should execute all commands as expected given multiple commands are sent to the context', (done) ->
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
      .catch done
      return


    it '[bugfix] should return the correct payload given an array at the domain event definition', (done) ->
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
      .catch done
      return


    describe 'given a command handler rejects with an error', ->

      dummyError = null

      beforeEach ->
        dummyError = new Error 'dummy error'


      it 'should re-throw an error with a descriptive message given the command handler triggers an error', ->
        exampleContext.addCommandHandlers
          CommandWithError: (params) ->
            new Promise ->
              throw dummyError

        exampleContext.command 'CommandWithError', foo: 'bar'
        .catch (error) ->
          expect(error).to.equal dummyError
          expect(error.message).to.contain 'exampleContext'
          expect(error.message).to.contain 'CommandWithError'
          expect(error.message).to.contain '{"foo":"bar"}'


      it 'should re-throw an error with a descriptive message given the command handler throws a synchronous error', ->
        exampleContext.addCommandHandlers
          CommandWithError: (params) ->
            throw dummyError

        exampleContext.command 'CommandWithError', foo: 'bar'
        .catch (error) ->
          expect(error).to.equal dummyError
          expect(error.message).to.contain 'exampleContext'
          expect(error.message).to.contain 'CommandWithError'
          expect(error.message).to.contain '{"foo":"bar"}'


      it 'should make it possible to access the original error message given the command handler triggers an error', ->
        exampleContext.addCommandHandlers
          CommandWithError: (params) ->
            new Promise ->
              throw dummyError

        exampleContext.command 'CommandWithError', foo: 'bar'
        .catch (error) ->
          expect(error).to.equal dummyError
          expect(error.originalErrorMessage).to.equal 'dummy error'


      it 'should throw a generic error given the command handler rejects without an error', ->
        exampleContext.addCommandHandlers
          CommandWhichRejectsWithoutAnError: (params) ->
            new Promise (resolve, reject) ->
              reject()

        exampleContext.command 'CommandWhichRejectsWithoutAnError', foo: 'bar'
        .catch (error) ->
          expect(error).to.be.an.instanceOf Error
          expect(error.message).to.contain 'exampleContext'
          expect(error.message).to.contain 'CommandWhichRejectsWithoutAnError'
          expect(error.message).to.contain '{"foo":"bar"}'


  describe 'creating an aggregate', ->

    it 'should emit the create domain event after creating an aggregate', (done) ->
      exampleContext = eventric.context 'Examplecontext'

      exampleContext.defineDomainEvent 'ExampleCreated', (params) ->
        @name = params.name
        @email = params.email

      class Example
        create: (params) ->
          @$emitDomainEvent 'ExampleCreated', params
      exampleContext.addAggregate 'Example', Example

      exampleContext.addCommandHandlers
        CreateExample: (params) ->
          @$aggregate.create 'Example', params
          .then (example) ->
            example.$save()

      exampleContext.subscribeToDomainEvent 'ExampleCreated', (domainEvent) ->
        expect(domainEvent.payload.name).to.be.equal 'John'
        expect(domainEvent.payload.email).to.be.equal 'john@example.com'
        done()

      exampleContext.initialize()
      .then ->
        exampleContext.command 'CreateExample',
          name: 'John'
          email: 'john@example.com'
      .catch done
      return
