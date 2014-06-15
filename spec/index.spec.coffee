eventric = require 'eventric'

describe 'Index', ->
  mongoDbEventStoreMock = null
  class MongoDbEventStoreMock
    initialize: sandbox.stub().yields null

  class BoundedContextStub
    initialize: sandbox.stub()

  beforeEach ->
    mongoDbEventStoreMock = new MongoDbEventStoreMock
    mockery.registerMock 'eventric-store-mongodb', mongoDbEventStoreMock

    mockery.registerMock './bounded_context', BoundedContextStub


  describe '#boundedContext', ->

    it 'should return a promise', ->
      someContext = eventric.boundedContext()
      expect(someContext).to.be.an.instanceof Promise


    it 'should reject if no name was given', (done) ->
      eventric.boundedContext().catch (error) ->
        expect(error).to.be.an.instanceof Error
        done()


    it 'should resolve if a name and store was given', (done) ->
      eventric.boundedContext
        name: 'someContext'
        store: {}
      .then (someContext) ->
        expect(someContext).to.be.an.instanceof Object
        done()


    it 'should initialize the mongodb event store per default if no store was given', ->
      eventric.boundedContext
        name: 'someContext'
      .then ->
        expect(mongoDbEventStoreMock.initialize.calledOnce).to.be.true
