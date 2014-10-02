PubSub = require 'eventric/src/pub_sub'

class EventBus

  constructor: ->
    @_pubSub = new PubSub()


  ###*
  * @name subscribeToDomainEventWithAggregateId
  *
  * @module EventBus
  ###
  subscribeToDomainEventWithAggregateId: (eventName, aggregateId, handlerFn, options = {}) ->
    @subscribeToDomainEvent "#{eventName}/#{aggregateId}", handlerFn, options


  ###*
  * @name subscribeToDomainEvent
  *
  * @module EventBus
  ###
  subscribeToDomainEvent: (eventName, handlerFn, options = {}) ->
    if options.isAsync
      @_pubSub.subscribeAsync eventName, handlerFn
    else
      @_pubSub.subscribe eventName, handlerFn


  ###*
  * @name subscribeToAllDomainEvents
  *
  * @module EventBus
  ###
  subscribeToAllDomainEvents: (handlerFn) ->
    @_pubSub.subscribe 'DomainEvent', handlerFn


  ###*
  * @name publishDomainEvent
  *
  * @module EventBus
  ###
  publishDomainEvent: (domainEvent, callback = ->) ->
    @_publish 'publish', domainEvent, callback


  ###*
  * @name publishDomainEventAndWait
  *
  * @module EventBus
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
