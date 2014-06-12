eventric = require 'eventric'

async        = eventric.require 'HelperAsync'
HelperEvents = eventric.require 'HelperEvents'
_            = eventric.require 'HelperUnderscore'

class DomainEventService

  _.extend @prototype, HelperEvents

  constructor: (@_eventStore) ->

  saveAndTrigger: (domainEvents, callback) ->
    # TODO: this should be an transaction to guarantee the consistency of the aggregate

    async.eachSeries domainEvents, (domainEvent, next) =>
      # store the DomainEvent
      @_eventStore.save domainEvent, (err) =>
        return next err if err

        eventName     = domainEvent.getName()
        aggregateId   = domainEvent.getAggregateId()
        aggregateName = domainEvent.getAggregateName()

        # now trigger the DomainEvent in multiple fashions
        @trigger 'DomainEvent', domainEvent
        @trigger aggregateName, domainEvent
        @trigger "#{aggregateName}:#{eventName}", domainEvent
        @trigger "#{aggregateName}/#{aggregateId}", domainEvent
        @trigger "#{aggregateName}:#{eventName}/#{aggregateId}", domainEvent

        next null
    , (err) =>
      return callback err if err
      callback null


module.exports = DomainEventService
