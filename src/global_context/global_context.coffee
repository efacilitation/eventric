# TODO: Simple approach for global projections without changing the Projection service. Refactor when adding EventStore
class GlobalContext

  constructor: (@_eventric) ->
    @name = 'Global'


  findDomainEventsByName: (findArguments...) ->
    findDomainEventsByName = @_getAllContexts().map (context) ->
      context.findDomainEventsByName findArguments...

    Promise.all findDomainEventsByName
    .then (domainEventsByContext) =>
      domainEvents = @_combineDomainEventsByContext domainEventsByContext
      @_sortDomainEventsByTimestamp domainEvents


  subscribeToDomainEvent: (eventName, domainEventHandler) ->
    subscribeToDomainEvents = @_getAllContexts().map (context) ->
      context.subscribeToDomainEvent eventName, domainEventHandler
    Promise.all subscribeToDomainEvents


  _getAllContexts: ->
    contextNames = @_eventric.getRegisteredContextNames()
    contextNames.map (contextName) =>
      @_eventric.remote contextName


  _combineDomainEventsByContext: (domainEventsByContext) ->
    domainEventsByContext.reduce (allDomainEvents, contextDomainEvents) ->
      allDomainEvents.concat contextDomainEvents
    , []


  _sortDomainEventsByTimestamp: (domainEvents) ->
    domainEvents.sort (firstEvent, secondEvent) ->
      firstEvent.timestamp - secondEvent.timestamp


module.exports = GlobalContext