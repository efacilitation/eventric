eventric = require 'eventric'
PubSub   = require './pub_sub'


class Projection

  constructor: ->
    @_handlerFunctions    = {}
    @_projectionInstances = {}


  initializeInstance: (ProjectionClass, params, context) ->
    new Promise (resolve, reject) =>
      projection = new ProjectionClass
      projection.eventBus = new PubSub()

      aggregateId = null
      projection.$subscribeHandlersWithAggregateId = (_aggregateId) ->
        aggregateId = _aggregateId
      projection.initialize? params

      projectionId = eventric.generateUid()

      eventNames = []
      eventHandlers = {}
      Object.keys(ProjectionClass::).forEach (handlerFnName) =>
        return unless handlerFnName.indexOf("handle") == 0
        eventName = handlerFnName.replace /^handle/, ''
        eventNames.push eventName

        handlerFn = ->
          projection[handlerFnName].apply projection, arguments
          projection.eventBus.publish 'changed', projection


        eventHandlers[eventName] = handlerFn

        if aggregateId
          subscriberId = context.subscribeToDomainEventWithAggregateId eventName, aggregateId, handlerFn
        else
          subscriberId = context.subscribeToDomainEvent eventName, handlerFn

        @_handlerFunctions[projectionId] ?= []
        @_handlerFunctions[projectionId].push subscriberId

      if aggregateId
        findEvents = context.findDomainEventsByNameAndAggregateId eventNames, aggregateId
      else
        findEvents = context.findDomainEventsByName eventNames

      findEvents.then (domainEvents) =>
        # TODO: performance optimizing, nextTick?
        for domainEvent in domainEvents
          eventHandlers[domainEvent.name] domainEvent

        @_projectionInstances[projectionId] = projection
        resolve projectionId


  getInstance: (projectionId) ->
    @_projectionInstances[projectionId]


  destroyInstance: (projectionId, context) ->
    for subscriberId in @_handlerFunctions[projectionId]
      context.unsubscribeFromDomainEvent subscriberId
    delete @_handlerFunctions[projectionId]
    delete @_projectionInstances[projectionId]



module.exports = new Projection