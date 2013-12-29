eventric = require 'eventric'

ReadAggregateRoot  = eventric 'ReadAggregateRoot'
DomainEventService = eventric 'DomainEventService'

# TODO so we obviously need the repository injected / given by constructor
Repository          = require('sixsteps-client')('Repository')

class CommandService

  constructor: ->
    @aggregateCache = {}

  create: (Aggregate) ->
    # create Aggregate
    aggregate = new Aggregate
    aggregate.create()

    # "trigger" the DomainEvent
    aggregate._domainEvent 'create'

    # store a reference to the Aggregate into a local cache
    @aggregateCache[aggregate._id] = aggregate

    # get events and hand them over to DomainEventService
    domainEvents = aggregate.getDomainEvents()
    DomainEventService.handle domainEvents

    # build ReadAggregate
    readAggregate = new ReadAggregateRoot

    # return the id of the newly generated Aggregate
    readAggregate

  fetch: (modelId, name, params) ->
    #TODO: implement!

  handle: (aggregateId, commandName, params) ->
    aggregate = Repository.fetchById aggregateId
    # TODO: Error handling if the function is not available
    aggregate[commandName] params
    domainEvents = aggregate.getDomainEvents()
    DomainEventService.handle domainEvents
    @

  remove: (modelId, name, params) ->
    #TODO: implement!

  destroy: (modelId, name, params) ->
    #TODO: implement!

# CommandService is a singelton!
commandService = new CommandService

module.exports = commandService