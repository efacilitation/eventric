describe 'ProjectionService', ->
  contextStub = null
  projectionService = null

  beforeEach ->
    Context = require '../context'
    contextStub = new Context
    sandbox.stub contextStub

    ProjectionService = require './'
    projectionService = new ProjectionService contextStub


  describe '#destroyInstance', ->

    it 'should reject with an error given no projection id', ->
      projectionService.destroyInstance()
      .catch (error) ->
        expect(error.message).to.match /Missing projection id/


    it 'should reject with an error given the projection is not initialized', ->
      projectionService.destroyInstance 'projection-1'
      .catch (error) ->
        expect(error.message).to.match /Projection with id .* is not initialized/


    describe 'given the projection was initialized', ->
      projectionInstance = null

      beforeEach ->
        projectionInstance =
          handleSampleDomainEvent: ->

        contextStub.findDomainEventsByName.returns Promise.resolve()
        contextStub.subscribeToDomainEvent.returns Promise.resolve 'subscriber-1'


      it 'should unsubscribe all domain event handler functions', ->
        projectionService.initializeInstance projectionInstance
        .then (projectionId) ->
          projectionService.destroyInstance projectionId
          .then ->
            expect(contextStub.unsubscribeFromDomainEvent).to.have.been.calledOnce
            expect(contextStub.unsubscribeFromDomainEvent).to.have.been.calledWith sinon.match.string


      it 'should remove the domain event handler functions', ->
        projectionService.initializeInstance projectionInstance
        .then (projectionId) ->
          expect(projectionService._handlerFunctions[projectionId]).to.be.not.undefined
          projectionService.destroyInstance projectionId
          .then ->
            expect(projectionService._handlerFunctions[projectionId]).to.be.undefined


      it 'should remove the projection instance', ->
        projectionService.initializeInstance projectionInstance
        .then (projectionId) ->
          expect(projectionService._projectionInstances[projectionId]).to.be.not.undefined
          projectionService.destroyInstance projectionId
          .then ->
            expect(projectionService._projectionInstances[projectionId]).to.be.undefined
