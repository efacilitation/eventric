# TODO: Add for each interface function a spec!

describe.only 'Projection Store Interface Feature', ->
  exampleContext = null

  beforeEach ->
    sandbox.spy eventric.StoreInMemory::, 'initialize'
    sandbox.spy eventric.StoreInMemory::, 'getProjectionStore'
    sandbox.spy eventric.StoreInMemory::, 'clearProjectionStore'

    exampleContext = eventric.context 'exampleContext'

    exampleContext.defineDomainEvents
      ExampleCreated: ->

    exampleContext.addProjection 'ExampleProjection', ->
      stores: ['inmemory']

      handleExampleCreated: (domainEvent) ->
        console.log @$store.inmemory.created = true

    exampleContext.initialize()


  it 'should call initialize with the correct params', ->
    expect(eventric.StoreInMemory::initialize)
      .to.have.been.calledWith sinon.match.has('name', 'exampleContext'), sinon.match.object


  it 'should call getProjectionStore with the correct params', ->
    expect(eventric.StoreInMemory::getProjectionStore).to.have.been.calledWith 'ExampleProjection'


  it 'should call clearProjectionStore with the correct params', ->
    expect(eventric.StoreInMemory::clearProjectionStore).to.have.been.calledWith 'ExampleProjection'
