eventric        = require 'eventric'
AggregateEntity = eventric 'AggregateEntity'

class AggregateRoot extends AggregateEntity

  constructor: ->
    @_domainEvents = []
    super

  create: ->
    # TODO this should be an unique id
    @_id = 1

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