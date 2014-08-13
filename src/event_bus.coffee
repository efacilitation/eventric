class EventBus

  constructor: ->
    @_handlers = {DomainEvent: []}


  subscribe: ([eventName, aggregateId]..., handler) ->
    @_handlers[eventName] ?= []
    @_handlers[eventName].push handler
    if aggregateId
      eventToSubscribe = "#{eventName}/#{aggregateId}"
      @_handlers[eventToSubscribe] ?= []
      @_handlers[eventToSubscribe].push handler


  # TODO: Implement unsubscribe
  #unsubscribe: ([eventName, aggregateId]..., handler) ->


  publish: (eventName, event, callback = ->) ->
    handlers = @_getRelevantHandlers eventName, event
    executeNextHandler = ->
      if handlers.length is 0
        callback()
      else
        handlers.shift() event, ->
        setTimeout executeNextHandler, 0
    setTimeout executeNextHandler, 0


  publishAndWait: (eventName, event, callback = ->) ->
    handlers = @_getRelevantHandlers eventName, event
    executeNextHandler = ->
      if handlers.length is 0
        callback()
      else
        handler = handlers.shift()
        if handler.length < 2
          handler(event)
          setTimeout executeNextHandler, 0
        else
          handler event, -> setTimeout executeNextHandler, 0
    setTimeout executeNextHandler, 0


  _getRelevantHandlers: (eventName, event) ->
    handlers = @_handlers['DomainEvent'].concat @_handlers[eventName] || []
    if event.aggregate and event.aggregate.id
      handlers.concat @_handlers["#{eventName}/#{event.aggregate.id}"] || []
    handlers


module.exports = EventBus
