eventric = require 'eventric'

_           = eventric 'HelperUnderscore'
async       = eventric 'HelperAsync'
MixinEvents = eventric 'MixinEvents'

class DomainEventService

  _.extend @prototype, MixinEvents

  constructor: (@_eventStore) ->

  saveAndTrigger: (domainEvents, callback) ->
    # TODO: this should be an transaction to guarantee the consistency of the aggregate

    async.eachSeries domainEvents, (domainEvent, next) =>
      # store the DomainEvent
      @_eventStore.save domainEvent, (err) =>
        return next err if err

        # now trigger the DomainEvent in multiple fashions
        @trigger 'DomainEvent', domainEvent
        @trigger domainEvent.aggregate.name, domainEvent
        @trigger "#{domainEvent.aggregate.name}:#{domainEvent.name}", domainEvent
        @trigger "#{domainEvent.aggregate.name}/#{domainEvent.aggregate.id}", domainEvent
        @trigger "#{domainEvent.aggregate.name}:#{domainEvent.name}/#{domainEvent.aggregate.id}", domainEvent

        next null
    , (err) =>
      return callback err if err
      callback null


module.exports = DomainEventService
