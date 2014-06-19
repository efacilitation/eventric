describe 'DomainEventService', ->
  DomainEvent        = eventric.require 'DomainEvent'
  DomainEventService = eventric.require 'DomainEventService'

  eventStore = null
  domainEventService = null
  beforeEach ->
    class EventStore
      find: ->
      save: ->
    eventStore = sinon.createStubInstance EventStore
    eventStore.save.yields null
    domainEventService = new DomainEventService
    domainEventService.initialize eventStore


  describe '#saveAndTrigger', ->

    domainEvent = null
    beforeEach ->
      domainEvent = new DomainEvent
        name: 'SomethingHappened'
        aggregate:
          id: 1
          name: 'Example'


    it 'should tell the EventStore to save the DomainEvent', (done) ->
      domainEventService.saveAndTrigger [domainEvent], (err) ->
        expect(eventStore.save.calledOnce).to.be.true
        done()

    it 'should trigger the given DomainEvent', (done) ->
      triggerSpy = sandbox.spy domainEventService, 'trigger'
      domainEventService.saveAndTrigger [domainEvent], (err) ->
        expect(triggerSpy.calledWith 'DomainEvent', domainEvent).to.be.true
        expect(triggerSpy.calledWith 'Example', domainEvent).to.be.true
        expect(triggerSpy.calledWith 'SomethingHappened', domainEvent).to.be.true
        done()