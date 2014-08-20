class EventBus

  constructor: ->
    @_handlers = {DomainEvent: []}


  subscribeToDomainEventWithAggregateId: (eventName, aggregateId, handler, options = {}) ->
    @subscribeToDomainEvent eventName, handler, options
    @subscribeToDomainEvent "#{eventName}/#{aggregateId}", handler, options


  subscribeToDomainEvent: (eventName, handler, options = {}) ->
    if options.isAsync
      handler.isAsync = true
    @_handlers[eventName] ?= []
    @_handlers[eventName].push handler


  # TODO: Implement unsubscribe
  #unsubscribe: ([eventName, aggregateId]..., handler) ->


  publishDomainEvent: (domainEvent, callback = ->) ->
    handlers = @_getRelevantHandlers domainEvent
    executeNextHandler = ->
      if handlers.length is 0
        callback()
      else
        handlers.shift() domainEvent, ->
        setTimeout executeNextHandler, 0
    setTimeout executeNextHandler, 0


  publishDomainEventAndWait: (domainEvent, callback = ->) ->
    handlers = @_getRelevantHandlers domainEvent
    executeNextHandler = ->
      if handlers.length is 0
        callback()
      else
        handler = handlers.shift()
        if handler.isAsync
          handler domainEvent, -> setTimeout executeNextHandler, 0
        else
          handler(domainEvent)
          setTimeout executeNextHandler, 0
    setTimeout executeNextHandler, 0


  _getRelevantHandlers: (domainEvent) ->
    handlers = @_handlers['DomainEvent'].concat @_handlers[domainEvent.name] || []
    if domainEvent.aggregate and domainEvent.aggregate.id
      handlers.concat @_handlers["#{domainEvent.name}/#{domainEvent.aggregate.id}"] || []
    handlers


module.exports = EventBus
