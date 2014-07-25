describe 'DomainService Feature', ->

  describe 'given we created and initialized some example context including a domain service', ->
    exampleContext = null
    specialStub = null
    beforeEach (done) ->
      exampleContext = eventric.context 'exampleContext'

      exampleContext.addCommandHandler 'DoSomething', (params, callback) ->
      	@$domainService 'DoSomethingSpecial', params, callback

      specialStub = sandbox.stub()
      exampleContext.addDomainService 'DoSomethingSpecial', (params, callback) =>
      	specialStub params.special
      	callback null, true

      exampleContext.initialize =>
        done()


    describe 'when we call the command', ->
      it 'then the domain service should be executed correctly', (done) ->
        exampleContext.command 'DoSomething', special: 'awesome'
        .then =>
          expect(specialStub).to.have.been.calledWith 'awesome'
          done()