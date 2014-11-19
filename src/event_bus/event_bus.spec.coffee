describe 'EventBus', ->

  eventBus = null
  pubSubStub = null
  beforeEach ->
    pubSubStub =
      subscribe: sandbox.stub().returns then: (next) -> next()
      subscribeAsync: sandbox.stub().returns then: (next) -> next()
      publish: sandbox.stub().returns then: (next) -> next()
      publishAsync: sandbox.stub().returns then: (next) -> next()
    mockery.registerMock 'eventric/src/pub_sub', sandbox.stub().returns pubSubStub
    EventBus = require 'eventric/src/event_bus'
    eventBus = new EventBus


  describe '#subscribeToDomainEvent', ->
    it 'should subscribe to the event with given event name', ->
      subscriberFn = ->
      eventBus.subscribeToDomainEvent 'SomeEvent', subscriberFn
      expect(pubSubStub.subscribe).to.have.been.calledWith 'SomeEvent', subscriberFn


  describe '#subscribeToDomainEventWithAggregateId', ->
    it 'should subscribe to the event with given event name and aggregate id', ->
      subscriberFn = ->
      eventBus.subscribeToDomainEventWithAggregateId 'SomeEvent', 12345, subscriberFn
      expect(pubSubStub.subscribe).to.have.been.calledWith 'SomeEvent/12345', subscriberFn


  describe '#subscribeToAllDomainEvents', ->
    it 'should subscribe to the generic event "DomainEvent"', ->
      subscriberFn = ->
      eventBus.subscribeToAllDomainEvents subscriberFn
      expect(pubSubStub.subscribe).to.have.been.calledWith 'DomainEvent', subscriberFn


  describe '#publishDomainEvent', ->
    beforeEach ->

    it 'should publish a generic "DomainEvent" event', ->
      domainEvent = name: 'SomeEvent'
      eventBus.publishDomainEvent domainEvent
      expect(pubSubStub.publish).to.have.been.calledWith 'DomainEvent', domainEvent


    it 'should then publish the given event', ->
      domainEvent = name: 'SomeEvent'
      eventBus.publishDomainEvent domainEvent
      expect(pubSubStub.publish).to.have.been.calledWith 'SomeEvent', domainEvent


    describe 'given an event with an aggregate id', ->
      it 'should publish an aggregate id specific event', ->
        domainEvent = name: 'SomeEvent', aggregate: id: 12345
        eventBus.publishDomainEvent domainEvent
        expect(pubSubStub.publish).to.have.been.calledWith 'SomeEvent/12345', domainEvent


  describe '#publishDomainEventAndWait', ->
    it 'should publish a generic "DomainEvent" event asynchronously', ->
      domainEvent = name: 'SomeEvent'
      eventBus.publishDomainEventAndWait domainEvent
      expect(pubSubStub.publishAsync).to.have.been.calledWith 'DomainEvent', domainEvent


    it 'should then publish the given event asynchronously', ->
      domainEvent = name: 'SomeEvent'
      eventBus.publishDomainEventAndWait domainEvent
      expect(pubSubStub.publishAsync).to.have.been.calledWith 'SomeEvent', domainEvent


    describe 'given an event with an aggregate id', ->
      it 'should publish an aggregate id specific event', ->
        domainEvent = name: 'SomeEvent', aggregate: id: 12345
        eventBus.publishDomainEventAndWait domainEvent
        expect(pubSubStub.publishAsync).to.have.been.calledWith 'SomeEvent/12345', domainEvent