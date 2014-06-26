eventric = require 'eventric'

async        = eventric.require 'HelperAsync'
HelperEvents = eventric.require 'HelperEvents'
_            = eventric.require 'HelperUnderscore'

class DomainEventService

  _.extend @prototype, HelperEvents

  initialize: (@_store, @_boundedContext) ->

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

        # now trigger the DomainEvent in multiple fashions
        nextTick = process?.nextTick ? setTimeout
        nextTick =>
          @trigger 'DomainEvent', domainEvent
          @trigger aggregateName, domainEvent
          @trigger eventName, domainEvent

          next null

    , (err) =>
      return callback err if err
      callback null


module.exports = DomainEventService
