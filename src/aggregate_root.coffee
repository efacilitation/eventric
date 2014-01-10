eventric        = require 'eventric'
AggregateEntity = eventric 'AggregateEntity'

class AggregateRoot extends AggregateEntity

  constructor: ->
    @_domainEvents = []
    super

  create: ->
    # TODO this should be an unique id
    @id = 1

  generateDomainEvent: (eventName, params={}) ->

    params.includeChanges = true unless params.includeChanges is false

    event =
      name: eventName
      metaData: @_metaData()

    if params.includeChanges
      event._changed = @_changes()
      @_clearChanges()

    @_domainEvents.push event


  getDomainEvents: ->
    @_domainEvents


module.exports = AggregateRoot