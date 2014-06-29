describe 'DomainEventService', ->
  DomainEvent        = eventric.require 'DomainEvent'
  DomainEventService = eventric.require 'DomainEventService'

  storeStub = null
  eventBusStub = null
  domainEventService = null
  beforeEach ->
    eventBusStub =
      publishDomainEvent: sandbox.stub()

    boundedContextStub =
      name: 'someContext'

    class Store
      find: ->
      save: ->
    storeStub = sinon.createStubInstance Store
    storeStub.save.yields null
    domainEventService = new DomainEventService
    domainEventService.initialize storeStub, eventBusStub, boundedContextStub


  describe '#saveAndPublish', ->

    domainEvent = null
    beforeEach ->
      domainEvent = new DomainEvent
        name: 'SomethingHappened'
        aggregate:
          id: 1
          name: 'Example'


    it 'should tell the Store to save the DomainEvent', (done) ->
      domainEventService.saveAndPublish [domainEvent], (err) ->
        expect(storeStub.save).to.have.been.calledWith 'someContext.events', domainEvent
        done()

    it 'should publish the domainevent on the eventbus', (done) ->
      domainEventService.saveAndPublish [domainEvent], (err) ->
        expect(eventBusStub.publishDomainEvent).to.have.been.calledWith domainEvent
        done()