eventric = require 'eventric'

_               = eventric.require 'HelperUnderscore'
DomainEvent     = eventric.require 'DomainEvent'
AggregateEntity = eventric.require 'AggregateEntity'

class Aggregate

  constructor: (name, definition, props) ->
    @_domainEvents = []

    @root = new AggregateEntity name
    _.extend @root, new definition.root

    @id = @root._generateUid()

    if typeof @root.create == 'function'
      # TODO: Should be ok as long as aggregates arent async
      errorCallbackCalled = false
      errorCallback = (err) =>
        errorCallbackCalled = true
        callback err

      @root.create props, errorCallback

      return if errorCallbackCalled
    else
      @root.applyProps props



  generateDomainEvent: (eventName, params={}) ->

    params.includeAggregateChanges = true unless params.includeAggregateChanges is false

    eventParams =
      name: eventName
      aggregate: @root.getMetaData()

    if params.includeAggregateChanges
      changes = @root.getChanges()
      if Object.keys(changes).length > 0
        eventParams.aggregate.changed = changes

    domainEvent = new DomainEvent eventParams
    @_domainEvents.push domainEvent


  getDomainEvents: ->
    @_domainEvents


  clearChanges: ->
    @root.clearChanges()


module.exports = Aggregate
