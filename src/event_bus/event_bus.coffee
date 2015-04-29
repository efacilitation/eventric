class EventBus

  constructor: (@_eventric) ->
    @_pubSub = new @_eventric.PubSub()


  subscribeToDomainEvent: (eventName, handlerFn, options = {}) ->
    @_pubSub.subscribe eventName, handlerFn


  subscribeToDomainEventWithAggregateId: (eventName, aggregateId, handlerFn, options = {}) ->
    @subscribeToDomainEvent "#{eventName}/#{aggregateId}", handlerFn, options


  subscribeToAllDomainEvents: (handlerFn) ->
    @_pubSub.subscribe 'DomainEvent', handlerFn


  publishDomainEvent: (domainEvent) ->
    new Promise (resolve, reject) =>
      @_pubSub.publish 'DomainEvent', domainEvent
      .then =>
        @_pubSub.publish domainEvent.name, domainEvent
      .then =>
        if domainEvent.aggregate and domainEvent.aggregate.id
          @_pubSub.publish "#{domainEvent.name}/#{domainEvent.aggregate.id}", domainEvent
          .then ->
            resolve()
        else
          resolve()

      .catch (err) ->
        reject err


module.exports = EventBus
