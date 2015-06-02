describe 'EventBus', ->

  eventBus = null
  pubSub = null

  beforeEach ->
    PubSub = require '../pub_sub'
    pubSub = new PubSub
    sandbox.spy pubSub, 'publish'
    sandbox.spy pubSub, 'subscribe'
    sandbox.spy pubSub, 'destroy'

    eventricStub =
      PubSub: -> pubSub

    EventBus = require './'
    eventBus = new EventBus eventricStub


  describe '#subscribeToDomainEvent', ->
    it 'should subscribe to the event with the correct event name', ->
      subscriberFunction = ->
      eventBus.subscribeToDomainEvent 'SomeEvent', subscriberFunction
      .then ->
        expect(pubSub.subscribe).to.have.been.calledWith 'SomeEvent', subscriberFunction


  describe '#subscribeToDomainEventWithAggregateId', ->
    it 'should subscribe to the event with the correct event name and aggregate id', ->
      subscriberFunction = ->
      eventBus.subscribeToDomainEventWithAggregateId 'SomeEvent', 12345, subscriberFunction
      .then ->
        expect(pubSub.subscribe).to.have.been.calledWith 'SomeEvent/12345', subscriberFunction


  describe '#subscribeToAllDomainEvents', ->
    it 'should subscribe to the generic event "DomainEvent"', ->
      subscriberFunction = ->
      eventBus.subscribeToAllDomainEvents subscriberFunction
      .then ->
        expect(pubSub.subscribe).to.have.been.calledWith 'DomainEvent', subscriberFunction


  describe '#publishDomainEvent', ->

    it 'should publish a generic "DomainEvent" event', ->
      domainEvent = name: 'SomeEvent'
      eventBus.publishDomainEvent domainEvent
      .then ->
        expect(pubSub.publish).to.have.been.calledWith 'DomainEvent', domainEvent


    it 'should publish an event with the correct event name', ->
      domainEvent = name: 'SomeEvent'
      eventBus.publishDomainEvent domainEvent
      .then ->
        expect(pubSub.publish).to.have.been.calledWith 'SomeEvent', domainEvent


    it 'should publish an aggregate id specific event given an event with an aggregate id', ->
      domainEvent = name: 'SomeEvent', aggregate: id: 12345
      eventBus.publishDomainEvent domainEvent
      .then ->
        expect(pubSub.publish).to.have.been.calledWith 'SomeEvent/12345', domainEvent


    it 'should wait to publish a domain event given a previous publish operation is still ongoing', ->
      publishedDomainEventNames = []
      eventBus.subscribeToAllDomainEvents (domainEvent) ->
        publishedDomainEventNames.push domainEvent.name

      eventBus.publishDomainEvent name: 'Event1'

      eventBus.publishDomainEvent name: 'Event2'
      .then ->
        expect(publishedDomainEventNames).to.deep.equal ['Event1', 'Event2']


  describe '#destroy', ->

    it 'should call destroy on the pub sub', ->
      eventBus.destroy()
      .then ->
        expect(pubSub.destroy).to.have.been.called


    it 'should remove the publish domain event method', ->
      eventBus.destroy()
      .then ->
        expect(eventBus.publishDomainEvent).to.be.undefined


    it 'should wait to resolve given there are ongoing publish operations', ->
      publishedDomainEventNames = []
      eventBus.subscribeToAllDomainEvents (domainEvent) ->
        publishedDomainEventNames.push domainEvent.name

      eventBus.publishDomainEvent name: 'Event1'
      eventBus.publishDomainEvent name: 'Event2'

      eventBus.destroy()
      .then ->
        expect(publishedDomainEventNames).to.deep.equal ['Event1', 'Event2']


