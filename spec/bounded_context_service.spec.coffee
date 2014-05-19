describe 'BoundedContextService', ->
  BoundedContextService  = eventric 'BoundedContextService'
  CommandService         = eventric 'CommandService'

  exampleBoundedContextMock = null

  beforeEach ->
    mockery.enable
        warnOnReplace: false
        warnOnUnregistered: false

    exampleBoundedContextMock =
      initialize: sinon.stub()
    mockery.registerMock 'bc/example', exampleBoundedContextMock
    BoundedContextService.load 'example', 'bc/example'


  afterEach ->
    mockery.deregisterAll()
    mockery.disable()


  describe '#load', ->
    describe 'given a bounded context with initialize function', ->
      it 'should execute the exported initialize function', ->
        expect(exampleBoundedContextMock.initialize.calledOnce).to.be.true


  describe '#get', ->
    describe 'given a name of a loaded bounded context', ->
      it 'should return the bounded context', ->
        result = BoundedContextService.get 'example'
        expect(result).to.deep.equal exampleBoundedContextMock