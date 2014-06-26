describe 'DomainEventService', ->
  DomainEvent        = eventric.require 'DomainEvent'
  DomainEventService = eventric.require 'DomainEventService'

  store = null
  domainEventService = null
  beforeEach ->
    boundedContextStub =
      name: 'someContext'

    class Store
      find: ->
      save: ->
    store = sinon.createStubInstance Store
    store.save.yields null
    domainEventService = new DomainEventService
    domainEventService.initialize store, boundedContextStub


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

    it 'should trigger the given DomainEvent', (done) ->
      triggerSpy = sandbox.spy domainEventService, 'trigger'
      domainEventService.saveAndTrigger [domainEvent], (err) ->
        expect(triggerSpy.calledWith 'DomainEvent', domainEvent).to.be.true
        expect(triggerSpy.calledWith 'Example', domainEvent).to.be.true
        expect(triggerSpy.calledWith 'SomethingHappened', domainEvent).to.be.true
        done()