describe 'Index', ->

  describe '#context', ->
    contextInstance = null
    contextStub = null

    beforeEach ->
      contextInstance =
        subscribeToAllDomainEvents: sandbox.stub()
      contextStub = sandbox.stub().returns contextInstance

      mockery.registerMock 'eventric/src/context', contextStub


    it 'should throw an error if no name given for the context', ->
      expect(-> new eventric.context).to.throw Error


    it 'should create a context instance', ->
      someContext = eventric.context 'someContext'
      expect(contextStub).to.have.been.calledWithNew


    it 'should register global domain event handlers on the context', ->
      someContext = eventric.context 'someContext'
      expect(contextInstance.subscribeToAllDomainEvents).to.have.been.called


  describe '#set/#get', ->

    it 'should save given key/value pairs', ->
      key = Math.random()
      value = Math.random()
      eventric.set key, value
      expect(eventric.get key).to.equal value


    it 'should return undefined for a not set key', ->
      key = Math.random()
      expect(eventric.get key).to.not.exist


    it 'should overwrite already defined values', ->
      key = Math.random()
      eventric.set key, '1'
      eventric.set key, '2'
      expect(eventric.get key).to.equal '2'