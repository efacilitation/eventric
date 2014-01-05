describe 'ReadAggregateRepositorySpec', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  ReadAggregateRepository = eventric 'ReadAggregateRepository'
  ReadAggregateRoot       = eventric 'ReadAggregateRoot'

  sandbox = null

  beforeEach ->
    sandbox = sinon.sandbox.create()

  afterEach ->
    sandbox.restore()

  describe '#findById', ->

    class FooReadAggregate extends ReadAggregateRoot

    readAggregateRepository = null

    beforeEach ->
      adapter =
        _findDomainEventsByAggregateId: ->
      readAggregateRepository = new ReadAggregateRepository adapter, FooReadAggregate


    it 'should return a instantiated ReadAggregate', ->
      expect(readAggregateRepository.findById(1)).to.be.a FooReadAggregate

    it 'should ask the adapter for the DomainEvents matching the AggregateId', ->
      adapter = sandbox.spy readAggregateRepository._adapter, '_findDomainEventsByAggregateId'
      readAggregateRepository.findById 27
      expect(adapter.calledWith(27)).to.be.ok()

    it 'should return a instantiated ReadAggregate containing the applied DomainEvents', ->
      sandbox.stub readAggregateRepository._adapter, '_findDomainEventsByAggregateId', -> id: 1, name: 'Foo'
      readAggregate = readAggregateRepository.findById 1
      expect(readAggregate.name).to.be 'Foo'