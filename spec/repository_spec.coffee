describe 'Repository', ->

  expect   = require 'expect'
  eventric = require 'eventric'

  Entity     = null
  Repository = null
  repository = null

  before ->
    Entity     = eventric 'AggregateEntity'
    Repository = eventric 'Repository'

  describe '#findByDomainEvent', ->

    it 'should yield its callback and return a entity given the domain event', (next) ->
      domainEvent = {}
      repository = new Repository
      repository.findByDomainEvent domainEvent, (err, entity) ->
        expect(err).not.to.be.ok()
        expect(entity).to.be.a Entity
        next()
