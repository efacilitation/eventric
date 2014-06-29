describe 'DomainEventService', ->
  DomainEvent        = eventric.require 'DomainEvent'
  DomainEventService = eventric.require 'DomainEventService'

  store = null
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
    store = sinon.createStubInstance Store
    store.save.yields null
    domainEventService = new DomainEventService
    domainEventService.initialize store, eventBusStub, boundedContextStub


  describe '#saveAndTrigger', ->

    domainEvent = null
    beforeEach ->
      domainEvent = new DomainEvent
        name: 'SomethingHappened'
        aggregate:
          id: 1
          name: 'Example'


    it 'should tell the Store to save the DomainEvent', (done) ->
      domainEventService.saveAndTrigger [domainEvent], (err) ->
        expect(store.save).to.have.been.calledWith 'someContext.events', domainEvent
        done()

    it 'should publish the domainevent on the eventbus', (done) ->
      domainEventService.saveAndTrigger [domainEvent], (err) ->
        expect(eventBusStub.publishDomainEvent).to.have.been.calledWith domainEvent
        done()