class EventBus

  constructor: (@_eventric) ->
    @_pubSub = new @_eventric.PubSub()
    @_publishQueue = new Promise (resolve) -> resolve()


  subscribeToDomainEvent: (eventName, handlerFn) ->
    @_pubSub.subscribe eventName, handlerFn


  subscribeToDomainEventWithAggregateId: (eventName, aggregateId, handlerFn) ->
    @subscribeToDomainEvent "#{eventName}/#{aggregateId}", handlerFn


  subscribeToAllDomainEvents: (handlerFn) ->
    @subscribeToDomainEvent 'DomainEvent', handlerFn


  publishDomainEvent: (domainEvent) ->
    @_enqueuePublishing =>
      @_publishDomainEvent domainEvent


  _enqueuePublishing: (publishOperation) ->
    @_publishQueue = @_publishQueue.then publishOperation


  _publishDomainEvent: (domainEvent) ->
    publishPasses = [
      @_pubSub.publish 'DomainEvent', domainEvent
      @_pubSub.publish domainEvent.name, domainEvent
    ]

    if domainEvent.aggregate?.id
      eventName = "#{domainEvent.name}/#{domainEvent.aggregate.id}"
      publishPasses.push @_pubSub.publish eventName, domainEvent

    Promise.all publishPasses


  destroy: ->
    Promise.all [
      @_publishQueue
      @_pubSub.destroy()
    ]
    .then =>
      @publishDomainEvent = undefined


module.exports = EventBus
