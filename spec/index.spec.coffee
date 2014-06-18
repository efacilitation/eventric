eventric = require 'eventric'

describe 'Index', ->

  boundedContextInstance = null
  BoundedContextStub = null

  beforeEach ->
    boundedContextInstance =
      addDomainEventHandler: sandbox.stub()
    BoundedContextStub = sandbox.stub().returns boundedContextInstance

    sandbox.stub eventric, 'require', -> BoundedContextStub


  describe '#boundedContext', ->

    it 'should throw an error if no name given for the bounded context', ->
      expect(-> new eventric.boundedContext).to.throw Error


    it 'should create a bounded context instance', ->
      someContext = eventric.boundedContext 'someContext'
      expect(BoundedContextStub).to.have.been.calledWithNew


    it 'should register global domain event handlers on the bounded context', ->
      someContext = eventric.boundedContext 'someContext'
      expect(boundedContextInstance.addDomainEventHandler).to.have.been.calledWith 'DomainEvent'


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