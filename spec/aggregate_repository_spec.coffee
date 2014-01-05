describe 'AggregateRepository', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  AggregateRepository = eventric 'AggregateRepository'
  AggregateRoot       = eventric 'AggregateRoot'

  sandbox = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

  afterEach ->
    sandbox.restore()

  describe '#findById', ->

    Foo = null
    aggregateRepository = null
    beforeEach ->
      adapter =
        _findDomainEventsByAggregateId: -> []
        _findAggregateIdsByDomainEventCriteria: -> []

      class Foo extends AggregateRoot

      aggregateRepository = new AggregateRepository adapter, Foo

    it 'should return a instantiated Aggregate', ->
      expect(aggregateRepository.findById(42)).to.be.a Foo

    it 'should ask the adapter for the DomainEvents matching the AggregateId', ->
      adapterSpy = sandbox.spy aggregateRepository._adapter, '_findDomainEventsByAggregateId'
      aggregateRepository.findById 27
      expect(adapterSpy.calledWith(27)).to.be.ok()

    it 'should return the Aggregate matching the given Id with all DomainEvents applied', ->
      testEvent =
        name: 'testEvent'
        metaData:
          id: 1
          name: 'Foo'
        _changed:
          props:
            name: 'John'

      sandbox.stub aggregateRepository._adapter, '_findDomainEventsByAggregateId', ->
        [ testEvent ]

      aggregate = aggregateRepository.findById 42
      expect(aggregate).to.be.a Foo
      expect(aggregate.name).to.be 'John'