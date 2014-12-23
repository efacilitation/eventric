###*
* @name EventBus
* @module EventBus
* @description
*
* The EventBus handles subscribing and publishing DomainEvents
###
class EventBus

  constructor: (@_eventric) ->
    @_pubSub = new @_eventric.PubSub()


  ###*
  * @name subscribeToDomainEvent
  * @module EventBus
  * @description Subscribe to DomainEvents
  *
  * @param {String} eventName The Name of DomainEvent to subscribe to
  * @param {Function} handlerFn Function to handle the DomainEvent
  ###
  subscribeToDomainEvent: (eventName, handlerFn, options = {}) ->
    if options.isAsync
      @_pubSub.subscribeAsync eventName, handlerFn
    else
      @_pubSub.subscribe eventName, handlerFn


  ###*
  * @name subscribeToDomainEventWithAggregateId
  * @module EventBus
  * @description Subscribe to DomainEvents by AggregateId
  *
  * @param {String} eventName The Name of DomainEvent to subscribe to
  * @param {String} aggregateId The AggregateId to subscribe to
  * @param {Function} handlerFn Function to handle the DomainEvent
  ###
  subscribeToDomainEventWithAggregateId: (eventName, aggregateId, handlerFn, options = {}) ->
    @subscribeToDomainEvent "#{eventName}/#{aggregateId}", handlerFn, options


  ###*
  * @name subscribeToAllDomainEvents
  * @module EventBus
  * @description Subscribe to all DomainEvents
  *
  * @param {Function} handlerFn Function to handle the DomainEvent
  ###
  subscribeToAllDomainEvents: (handlerFn) ->
    @_pubSub.subscribe 'DomainEvent', handlerFn


  ###*
  * @name publishDomainEvent
  * @module EventBus
  * @description Publish a DomainEvent on the Bus
  ###
  publishDomainEvent: (domainEvent) ->
    @_publish 'publish', domainEvent


  ###*
  * @name publishDomainEventAndWait
  * @module EventBus
  * @description Publish a DomainEvent on the Bus and wait for all Projections to call their promise.resolve
  ###
  publishDomainEventAndWait: (domainEvent) ->
    @_publish 'publishAsync', domainEvent


  _publish: (publishMethod, domainEvent) ->
    new Promise (resolve, reject) =>
      @_pubSub[publishMethod] 'DomainEvent', domainEvent
      .then =>
        @_pubSub[publishMethod] domainEvent.name, domainEvent
      .then =>
        if domainEvent.aggregate and domainEvent.aggregate.id
          @_pubSub[publishMethod] "#{domainEvent.name}/#{domainEvent.aggregate.id}", domainEvent
          .then ->
            resolve()
        else
          resolve()

      .catch (err) ->
        reject err


module.exports = EventBus
