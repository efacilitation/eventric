eventric = require 'eventric'

Entity = eventric 'AggregateEntity'

class Repository

  findByDomainEvent: (domainEvent, next) ->
    # TODO this is only an example implementation
    entity = new Entity
    next null, entity

  fetchById: ->

  save: (user, callback) ->
    callback null, user

  findOne: (query, callback) ->
    user =
      email: 'user@test.com'
      passwordHash: '$2a$10$JfaXMYjS5VknafBfFEynj.FhJUAHrcAyMEFcgVUNSZKrFxpuZmrW2'
    callback null, user

module.exports = Repository
