describe 'EventBus', ->

  eventBus = null
  pubSubStub = null

  beforeEach ->
    PubSub = require '../pub_sub'
    pubSubStub = new PubSub
    sandbox.stub(pubSubStub, 'publish').returns new Promise (resolve) -> resolve()
    sandbox.stub(pubSubStub, 'subscribe').returns new Promise (resolve) -> resolve()
    sandbox.stub(pubSubStub, 'destroy').returns new Promise (resolve) -> resolve()

    eventricStub =
      PubSub: -> pubSubStub

    EventBus = require './'
    eventBus = new EventBus eventricStub


  describe '#subscribeToDomainEvent', ->
    it 'should subscribe to the event with the correct event name', ->
      subscriberFunction = ->
      eventBus.subscribeToDomainEvent 'SomeEvent', subscriberFunction
      .then ->
        expect(pubSubStub.subscribe).to.have.been.calledWith 'SomeEvent', subscriberFunction


  describe '#subscribeToDomainEventWithAggregateId', ->
    it 'should subscribe to the event with the correct event name and aggregate id', ->
      subscriberFunction = ->
      eventBus.subscribeToDomainEventWithAggregateId 'SomeEvent', 12345, subscriberFunction
      .then ->
        expect(pubSubStub.subscribe).to.have.been.calledWith 'SomeEvent/12345', subscriberFunction


  describe '#subscribeToAllDomainEvents', ->
    it 'should subscribe to the generic event "DomainEvent"', ->
      subscriberFunction = ->
      eventBus.subscribeToAllDomainEvents subscriberFunction
      .then ->
        expect(pubSubStub.subscribe).to.have.been.calledWith 'DomainEvent', subscriberFunction


  describe '#publishDomainEvent', ->

    it 'should publish a generic "DomainEvent" event', ->
      domainEvent = name: 'SomeEvent'
      eventBus.publishDomainEvent domainEvent
      .then ->
        expect(pubSubStub.publish).to.have.been.calledWith 'DomainEvent', domainEvent


    it 'should publish an event with the correct event name', ->
      domainEvent = name: 'SomeEvent'
      eventBus.publishDomainEvent domainEvent
      .then ->
        expect(pubSubStub.publish).to.have.been.calledWith 'SomeEvent', domainEvent


    it 'should publish an aggregate id specific event given an event with an aggregate id', ->
      domainEvent = name: 'SomeEvent', aggregate: id: 12345
      eventBus.publishDomainEvent domainEvent
      .then ->
        expect(pubSubStub.publish).to.have.been.calledWith 'SomeEvent/12345', domainEvent


    it 'should wait to publish a domain event given a previous publish operation is still ongoing', ->
      pubSubStub.publish.onFirstCall().returns new Promise (resolve) -> setTimeout resolve, 15
      pubSubStub.publish.onSecondCall().returns new Promise (resolve) -> resolve()

      eventBus.publishDomainEvent name: 'Event1'
      eventBus.publishDomainEvent name: 'Event2'
      .then ->
        expect(pubSubStub.publish.getCall(1).args[0]).to.equal 'Event1'
        expect(pubSubStub.publish.getCall(3).args[0]).to.equal 'Event2'


  describe '#destroy', ->

    it 'should call destroy on the pub sub', ->
      eventBus.destroy()
      .then ->
        expect(pubSubStub.destroy).to.have.been.called


    it 'should remove the publish domain event method', ->
      eventBus.destroy()
      .then ->
        expect(eventBus.publishDomainEvent).to.be.undefined





