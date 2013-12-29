eventric = require 'eventric'

Entity = eventric 'AggregateEntity'

class Repository

  findByDomainEvent: (domainEvent, next) ->
    # TODO this is only an example implementation
    entity = new Entity
    next null, entity

  fetchById: ->

# Repository is a singelton!
repository = new Repository

module.exports = repository
