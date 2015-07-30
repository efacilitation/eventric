# TODO: Add for each interface function a spec!
describe 'Projection Store Interface Feature', ->
  exampleContext = null

  StoreInMemory = null

  beforeEach ->
    StoreInMemory = require '../store/inmemory'
    sandbox.spy StoreInMemory::, 'initialize'
    sandbox.spy StoreInMemory::, 'getProjectionStore'
    sandbox.spy StoreInMemory::, 'clearProjectionStore'

    exampleContext = eventric.context 'exampleContext'

    exampleContext.defineDomainEvents
      ExampleCreated: ->

    exampleContext.addProjection 'ExampleProjection', ->
      stores: ['inmemory']

      handleExampleCreated: (domainEvent) ->
        @$store.inmemory.created = true

    exampleContext.initialize()


  it 'should call initialize with the correct params', ->
    expect(StoreInMemory::initialize)
      .to.have.been.calledWith sinon.match.has('name', 'exampleContext'), sinon.match.object


  it 'should call getProjectionStore with the correct params', ->
    expect(StoreInMemory::getProjectionStore).to.have.been.calledWith 'ExampleProjection'


  it 'should call clearProjectionStore with the correct params', ->
    expect(StoreInMemory::clearProjectionStore).to.have.been.calledWith 'ExampleProjection'
