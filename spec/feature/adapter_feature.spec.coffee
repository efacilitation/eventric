describe 'Adapter Feature', ->

  eventStoreMock = null
  beforeEach ->
    eventStoreMock =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null

  describe 'given we created and initialized some example bounded microContext including an aggregate', ->
    exampleMicroContext = null
    beforeEach ->
      exampleMicroContext = eventric.microContext 'exampleMicroContext'
      exampleMicroContext.set 'store', eventStoreMock
      exampleMicroContext.addAggregate 'Example', class Example


    describe 'when we use a command which calls a previously added adapter function', ->
      ExampleAdapter = null
      beforeEach ->
        class ExampleAdapter
          someAdapterFunction: sandbox.stub()
        exampleMicroContext.addAdapter 'exampleAdapter', ExampleAdapter

        exampleMicroContext.addCommandHandler 'doSomething', (params, callback) ->
              @$adapter('exampleAdapter').someAdapterFunction()
              callback()


      it 'then it should have called the adapter function', (done) ->
        exampleMicroContext.initialize =>
          exampleMicroContext.command
            name: 'doSomething'
          , ->
            expect(ExampleAdapter::someAdapterFunction).to.have.been.calledOnce
            done()