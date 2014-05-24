describe 'BoundedContextService', ->
  BoundedContextService  = eventric.require 'BoundedContextService'
  CommandService         = eventric.require 'CommandService'

  exampleBoundedContextMock = null

  beforeEach ->
    exampleBoundedContextMock =
      initialize: sinon.stub()
    mockery.registerMock 'bc/example', exampleBoundedContextMock
    BoundedContextService.load 'example', 'bc/example'


  describe '#load', ->
    describe 'given a bounded context with initialize function', ->
      it 'should execute the exported initialize function', ->
        expect(exampleBoundedContextMock.initialize.calledOnce).to.be.true


  describe '#get', ->
    describe 'given a name of a loaded bounded context', ->
      it 'should return the bounded context', ->
        result = BoundedContextService.get 'example'
        expect(result).to.deep.equal exampleBoundedContextMock