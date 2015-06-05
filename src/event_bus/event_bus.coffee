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
    new Promise (resolve, reject) =>
      @_enqueuePublishing =>
        @_publishDomainEvent(domainEvent)
        .then(resolve).catch(reject)


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
    @_publishQueue.then =>
      @_pubSub.destroy().then =>

        @publish = (domainEvent, payload) ->
          Promise.reject new Error """
              Event Bus was destroyed, cannot publish #{domainEvent.name} with payload #{JSON.stringify domainEvent.payload}
            """


module.exports = EventBus
