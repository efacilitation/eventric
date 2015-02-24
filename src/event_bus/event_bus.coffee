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
