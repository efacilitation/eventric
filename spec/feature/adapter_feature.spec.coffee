describe 'Adapter Feature', ->

  eventStoreMock = null
  beforeEach ->
    eventStoreMock =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null

  describe 'given we created and initialized some example bounded context including an aggregate', ->
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.boundedContext 'exampleContext'
      exampleContext.set 'store', eventStoreMock
      exampleContext.addAggregate 'Example', class Example


    describe 'when we use a command which calls a previously added adapter function', ->
      ExampleAdapter = null
      beforeEach ->
        class ExampleAdapter
          someAdapterFunction: sandbox.stub()
        exampleContext.addAdapter 'exampleAdapter', ExampleAdapter

        exampleContext.addCommandHandler 'doSomething', (params, callback) ->
              @$adapter('exampleAdapter').someAdapterFunction()
              callback()


      it 'then it should have called the adapter function', (done) ->
        exampleContext.initialize()
        exampleContext.command
          name: 'doSomething'
        , ->
          expect(ExampleAdapter::someAdapterFunction).to.have.been.calledOnce
          done()