PubSub = require 'eventric/src/pub_sub'

###*
* @name EventBus
* @module EventBus
* @description
*
* The EventBus handles subscribing and publishing DomainEvents
###
class EventBus

  constructor: ->
    @_pubSub = new PubSub()


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
  publishDomainEvent: (domainEvent, callback = ->) ->
    @_publish 'publish', domainEvent, callback


  ###*
  * @name publishDomainEventAndWait
  * @module EventBus
  * @description Publish a DomainEvent on the Bus and wait for all Projections to call their callback-Handler
  ###
  publishDomainEventAndWait: (domainEvent, callback = ->) ->
    @_publish 'publishAsync', domainEvent, callback


  _publish: (publishMethod, domainEvent, callback = ->) ->
    @_pubSub[publishMethod] 'DomainEvent', domainEvent, =>
      @_pubSub[publishMethod] domainEvent.name, domainEvent, =>
        if domainEvent.aggregate and domainEvent.aggregate.id
          @_pubSub[publishMethod] "#{domainEvent.name}/#{domainEvent.aggregate.id}", domainEvent, callback
        else
          callback()


module.exports = EventBus
