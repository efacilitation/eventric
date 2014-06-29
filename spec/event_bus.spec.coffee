describe 'EventBus', ->
  DomainEvent = eventric.require 'DomainEvent'
  EventBus    = eventric.require 'EventBus'

  store = null
  eventBus = null
  beforeEach ->
    eventBus = new EventBus


  describe '#publishDomainEvent', ->

    domainEvent = null
    beforeEach ->
      domainEvent = new DomainEvent
        name: 'SomethingHappened'
        aggregate:
          id: 1
          name: 'Example'


    it 'should trigger the given DomainEvent', ->
      triggerSpy = sandbox.spy eventBus, 'trigger'
      eventBus.publishDomainEvent domainEvent
      expect(triggerSpy.calledWith 'DomainEvent', domainEvent).to.be.true
      expect(triggerSpy.calledWith 'SomethingHappened', domainEvent).to.be.true