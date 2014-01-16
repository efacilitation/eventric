describe 'AggregateRepository', ->

  sinon    = require 'sinon'
  expect   = require 'expect.js'
  eventric = require 'eventric'

  AggregateRepository = eventric 'AggregateRepository'
  AggregateRoot       = eventric 'AggregateRoot'
  EventStore          = eventric 'EventStoreInMemory'

  before ->
    EventStore.save
      name: 'testEvent'
      aggregate:
        id: 42
        name: 'Foo'
        changed:
          props:
            name: 'John'

  after ->
    EventStore.clear()

  sandbox = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

  afterEach ->
    sandbox.restore()

  describe '#findById', ->

    Foo = null
    aggregateRepository = null
    beforeEach ->

      class Foo extends AggregateRoot

      aggregateRepository = new AggregateRepository EventStore
      aggregateRepository.registerClass 'Foo', Foo

    it 'should return a instantiated Aggregate', ->
      aggregateRepository.findById 'Foo', 42, (err, aggregate) ->
        expect(aggregate).to.be.a Foo

    it 'should ask the EventStore for DomainEvents matching the AggregateId', ->
      EventStoreSpy = sandbox.spy EventStore, 'findByAggregateId'
      aggregateRepository.findById 'Foo', 42, ->
      expect(EventStoreSpy.calledWith(42)).to.be.ok()

    it 'should return the Aggregate matching the given Id with all DomainEvents applied', ->
      aggregateRepository.findById 'Foo', 42, (err, aggregate) ->
        expect(aggregate).to.be.a Foo
        expect(aggregate.name).to.be 'John'