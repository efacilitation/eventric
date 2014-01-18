describe 'AggregateRepository', ->

  sinon    = require 'sinon'
  expect   = require 'expect.js'
  eventric = require 'eventric'

  AggregateRepository = eventric 'AggregateRepository'
  AggregateRoot       = eventric 'AggregateRoot'
  EventStore          = eventric 'MongoDBEventStore'


  describe '#findById', ->

    Foo = null
    aggregateRepository = null
    EventStoreStub = null
    beforeEach ->

      EventStoreStub = sinon.createStubInstance EventStore

      class Foo extends AggregateRoot

      aggregateRepository = new AggregateRepository EventStoreStub
      aggregateRepository.registerClass 'Foo', Foo

    it 'should return a instantiated Aggregate', ->
      aggregateRepository.findById 'Foo', 42, (err, aggregate) ->
        expect(aggregate).to.be.a Foo

    it 'should ask the EventStore for DomainEvents matching the AggregateId', ->
      aggregateRepository.findById 'Foo', 42, ->
      expect(EventStoreStub.findByAggregateId.calledWith('Foo', 42)).to.be.ok()

    it 'should return the Aggregate matching the given Id with all DomainEvents applied', ->
      aggregateRepository.findById 'Foo', 42, (err, aggregate) ->
        expect(aggregate).to.be.a Foo
        expect(aggregate.name).to.be 'John'