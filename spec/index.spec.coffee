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

    sandbox.stub eventric, 'require', -> BoundedContextStub


  describe '#boundedContext', ->

    describe 'given no name', ->
      it 'should return an error', ->
        someContext = eventric.boundedContext()
        expect(someContext).to.be.an.instanceof Error


    describe 'given no store', ->
      it 'should return an error', ->
        someContext = eventric.boundedContext
          name: 'someContext'
        expect(someContext).to.be.an.instanceof Error


    describe 'given a name and a store', ->
      storeStub = null
      someContext = null
      beforeEach ->
        storeStub = sandbox.stub()
        someContext = eventric.boundedContext
          name: 'someContext'
          store: storeStub


      it 'should call initialize on the BoundedContext with the name and store', ->
        expect(BoundedContextStub::initialize).to.have.been.calledWith 'someContext', storeStub


      it 'should return the BoundedContext', ->
        expect(someContext).to.be.an.instanceof BoundedContextStub


    describe 'given a name and a global store', ->
      it 'should call initialize on the BoundedContext with the name and global store', ->
        globalStoreStub = sandbox.stub()
        eventric.set 'store', globalStoreStub
        someContext = eventric.boundedContext
          name: 'someContext'

        expect(BoundedContextStub::initialize).to.have.been.calledWith 'someContext', globalStoreStub
