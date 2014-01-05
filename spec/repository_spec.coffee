describe 'Repository', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  AggregateEntity         = eventric 'AggregateEntity'
  ReadAggregateRoot       = eventric 'ReadAggregateRoot'
  ReadAggregateRepository = eventric 'ReadAggregateRepository'
  Repository              = eventric 'Repository'

  readAggregateRepository = null
  sandbox = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

    adapter =
      _findDomainEventsByAggregateId: ->
      _findAggregateIdsByDomainEventCriteria: ->

    class ReadFoo extends ReadAggregateRoot

    readAggregateRepository = new ReadAggregateRepository adapter, ReadFoo

  afterEach ->
    sandbox.restore()

  describe '#_findDomainEventsByAggregateId', ->

    it 'should ask the given RepositoryAdapter to find all DomainEvents matching the given AggregateId', ->
      adapter = sandbox.spy readAggregateRepository._adapter, '_findDomainEventsByAggregateId'
      readAggregateRepository._findDomainEventsByAggregateId 27
      expect(adapter.calledWith(27)).to.be.ok()

  describe '#_findAggregateIdsByDomainEventCriteria', ->

    it 'should ask the given RepositoryAdapter to find all AggregateIds matching the given criteria', ->
      adapter = sandbox.spy readAggregateRepository._adapter, '_findAggregateIdsByDomainEventCriteria'
      criteria = {}
      readAggregateRepository._findAggregateIdsByDomainEventCriteria criteria
      expect(adapter.calledWith(criteria)).to.be.ok()


  describe '#findByDomainEvent', ->

    it 'should yield its callback and return a entity given the domain event', (next) ->
      domainEvent = {}
      repository = new Repository
      repository.findByDomainEvent domainEvent, (err, entity) ->
        expect(err).not.to.be.ok()
        expect(entity).to.be.a AggregateEntity
        next()