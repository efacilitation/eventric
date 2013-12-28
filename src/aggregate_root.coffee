Entity = require './entity'

class AggregateRoot extends Entity

  constructor: ->
    @_domainEvents = []
    super

  _domainEvent: (eventName, params={}) ->

    params.includeChanges = true unless params.includeChanges is false

    event =
      name: eventName
      data: @_data()

    if params.includeChanges
      event.changed = @_changes()
      @_clearChanges()

    @_domainEvents.push event


  getDomainEvents: ->
    @_domainEvents


module.exports = AggregateRoot