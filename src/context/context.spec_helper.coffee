class GlobalProjectionFeatureSpecHelper

  createContextWithOneAggregate: ({contextName, aggregateName}) ->
    createdEventName = aggregateName + 'Created'
    modifiedEventName = aggregateName + 'Modified'

    class Aggregate
      create: ->
        @$emitDomainEvent createdEventName


      modify: ->
        @$emitDomainEvent modifiedEventName


    commandHandlers =
      CreateAggregate: ->
        @$aggregate.create aggregateName
        .then (aggregate) ->
          aggregate.$save()


      ModifyAggregate: ({aggregateId}) ->
        @$aggregate.load aggregateName, aggregateId
        .then (aggregate) ->
          aggregate.modify()
          aggregate.$save()


    context = eventric.context contextName
    context.defineDomainEvent createdEventName, ->
    context.defineDomainEvent modifiedEventName, ->
    context.addAggregate aggregateName, Aggregate
    context.addCommandHandlers commandHandlers
    return context


module.exports = new GlobalProjectionFeatureSpecHelper
