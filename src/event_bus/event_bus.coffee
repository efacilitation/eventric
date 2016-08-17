Subscriber = require './subscriber'

class EventBus

  constructor: ->
    @_subscribers = []
    @_subscriberId = 0
    @_eventPublishQueue = Promise.resolve()
    @_isDestroyed = false


  subscribeToAllDomainEvents: (subscriberFunction) ->
    @_subscribe '*', subscriberFunction


  subscribeToDomainEvent: (eventName, subscriberFunction) ->
    @_subscribe eventName, subscriberFunction


  subscribeToDomainEventWithAggregateId: (eventName, aggregateId, subscriberFunction) ->
    @_subscribe "#{eventName}/#{aggregateId}", subscriberFunction


  _subscribe: (eventName, subscriberFunction) ->
    new Promise (resolve) =>
      subscriber = new Subscriber
        eventName: eventName
        subscriberFunction: subscriberFunction
        subscriberId: @_getNextSubscriberId()
      @_subscribers.push subscriber
      resolve subscriber.subscriberId


  _getNextSubscriberId: ->
    @_subscriberId++


  publishDomainEvent: (domainEvent) ->
    new Promise (resolve, reject) =>
      @_verifyPublishIsPossible domainEvent

      publishOperation = =>
        return @_notifySubscribers domainEvent
        .then resolve
        .catch reject

      @_enqueueEventPublishing publishOperation


  _verifyPublishIsPossible: (domainEvent) ->
    if @_isDestroyed
      errorMessage = """
        Event Bus was destroyed, cannot publish #{domainEvent.name}
        with payload #{JSON.stringify domainEvent.payload}
      """
      if domainEvent.aggregate?.id
        errorMessage += " and aggregate id #{domainEvent.aggregate.id}"
      throw new Error errorMessage


  _notifySubscribers: (domainEvent) ->
    Promise.resolve()
    .then =>
      subscribers = @_getSubscribersForDomainEvent domainEvent
      return Promise.all subscribers.map (subscriber) -> subscriber.subscriberFunction domainEvent


  _getSubscribersForDomainEvent: (domainEvent) ->
    subscribers = @_subscribers.filter (subscriber) -> subscriber.eventName is '*'
    subscribers = subscribers.concat @_subscribers.filter (subscriber) -> subscriber.eventName is domainEvent.name
    if domainEvent.aggregate?.id
      subscribers = subscribers.concat @_subscribers.filter (subscriber) ->
        subscriber.eventName is "#{domainEvent.name}/#{domainEvent.aggregate.id}"

    return subscribers


  _enqueueEventPublishing: (publishOperation) ->
    @_eventPublishQueue = @_eventPublishQueue.then publishOperation


  unsubscribe: (subscriberId) ->
    Promise.resolve().then =>
      @_subscribers = @_subscribers.filter (subscriber) -> subscriber.subscriberId isnt subscriberId


  destroy: ->
    @_waitForEventPublishQueue().then =>
      @_isDestroyed = true


  _waitForEventPublishQueue: ->
    currentEventPublishQueue = @_eventPublishQueue
    currentEventPublishQueue.then =>
      if @_eventPublishQueue isnt currentEventPublishQueue
        @_waitForEventPublishQueue()


module.exports = EventBus
