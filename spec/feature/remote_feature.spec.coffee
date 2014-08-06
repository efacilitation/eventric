describe 'Remote Feature', ->

  describe 'given we created and initialized some example context', ->
    exampleContext  = null
    doSomethingStub = null
    beforeEach (done) ->
      exampleContext = eventric.context 'Example'

      doSomethingStub = sandbox.stub()

      exampleContext.addCommandHandlers
        DoSomething: (params, callback) ->
          doSomethingStub()
          callback()

      exampleContext.initialize ->
        done()


    it 'then it should be able to receive commands over a remote', (done) ->
      exampleRemote = eventric.remote 'Example'
      exampleRemote.command 'DoSomething'
      .then ->
        expect(doSomethingStub).to.have.been.calledOnce
        done()
