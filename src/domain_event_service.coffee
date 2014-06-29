eventric = require 'eventric'

async        = eventric.require 'HelperAsync'
_            = eventric.require 'HelperUnderscore'

class DomainEventService

  initialize: (@_store, @_eventBus, @_boundedContext) ->

  saveAndTrigger: (domainEvents, callback) ->
    # TODO: this should be an transaction to guarantee consistency

    async.eachSeries domainEvents, (domainEvent, next) =>
      # store the DomainEvent
      collectionName = "#{@_boundedContext.name}.events"
      @_store.save collectionName, domainEvent, (err) =>
        return next err if err

        eventName     = domainEvent.name
        aggregateId   = domainEvent.aggregate.id
        aggregateName = domainEvent.aggregate.name

        # publish the domainevent on the eventbus
        nextTick = process?.nextTick ? setTimeout
        nextTick =>
          @_eventBus.publishDomainEvent domainEvent

          next null

    , (err) =>
      return callback err if err
      callback null


module.exports = DomainEventService
