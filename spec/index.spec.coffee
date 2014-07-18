eventric = require 'eventric'

describe 'Index', ->

  microContextInstance = null
  MicroContextStub = null

  beforeEach ->
    microContextInstance =
      addDomainEventHandler: sandbox.stub()
    MicroContextStub = sandbox.stub().returns microContextInstance

    sandbox.stub eventric, 'require', -> MicroContextStub


  describe '#microContext', ->

    it 'should throw an error if no name given for the bounded microContext', ->
      expect(-> new eventric.microContext).to.throw Error


    it 'should create a bounded microContext instance', ->
      someMicroContext = eventric.microContext 'someMicroContext'
      expect(MicroContextStub).to.have.been.calledWithNew


    it 'should register global domain event handlers on the bounded microContext', ->
      someMicroContext = eventric.microContext 'someMicroContext'
      expect(microContextInstance.addDomainEventHandler).to.have.been.calledWith 'DomainEvent'


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